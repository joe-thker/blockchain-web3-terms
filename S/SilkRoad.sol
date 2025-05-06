// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SilkRoadSuite
/// @notice Escrow, Reputation, and Mixer modules reflecting Silk Road patterns
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Basic reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Escrow Marketplace
contract SilkRoadEscrow is Base, ReentrancyGuard {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, REFUNDED }
    struct Trade {
        address buyer;
        address vendor;
        uint256 amount;
        State   state;
        uint256 deadline;    // dispute timeout
    }
    mapping(uint256 => Trade) public trades;
    uint256 public nextTrade;

    // --- Attack: buyer/deployer withdraws immediately, no checks
    function createTradeInsecure(address vendor) external payable {
        trades[nextTrade++] = Trade(msg.sender, vendor, msg.value, State.COMPLETE, 0);
        // funds immediately considered delivered
        payable(vendor).transfer(msg.value);
    }

    // --- Defense: escrow with mutual release & timeout
    function createTradeSecure(address vendor, uint256 disputePeriod) external payable {
        require(msg.value > 0, "No funds");
        trades[nextTrade] = Trade(msg.sender, vendor, msg.value, State.AWAITING_DELIVERY, block.timestamp + disputePeriod);
        nextTrade++;
    }

    // buyer confirms delivery
    function confirmDeliverySecure(uint256 tradeId) external {
        Trade storage t = trades[tradeId];
        require(msg.sender == t.buyer && t.state == State.AWAITING_DELIVERY, "Not allowed");
        t.state = State.COMPLETE;
        payable(t.vendor).transfer(t.amount);
    }

    // vendor claims refund if buyer silent past deadline
    function claimTimeoutSecure(uint256 tradeId) external nonReentrant {
        Trade storage t = trades[tradeId];
        require(msg.sender == t.vendor && t.state == State.AWAITING_DELIVERY, "Not vendor or wrong state");
        require(block.timestamp >= t.deadline, "Too early");
        t.state = State.COMPLETE;
        payable(t.vendor).transfer(t.amount);
    }

    // buyer can refund before delivery confirm
    function refundSecure(uint256 tradeId) external nonReentrant {
        Trade storage t = trades[tradeId];
        require(msg.sender == t.buyer && t.state == State.AWAITING_DELIVERY, "Not buyer or wrong state");
        t.state = State.REFUNDED;
        payable(t.buyer).transfer(t.amount);
    }
}

/// 2) Reputation System
contract SilkRoadReputation is Base {
    struct Order { address buyer; address vendor; bool paid; }
    mapping(uint256 => Order) public orders;
    mapping(uint256 => mapping(address => bool)) public rated;   // orderId → buyer → rated
    mapping(address => uint256) public vendorScore;
    uint256 public nextOrder;

    // --- Attack: fake orders & repeated ratings
    function recordOrderInsecure(address buyer, address vendor) external {
        orders[nextOrder++] = Order(buyer, vendor, false);
    }
    function rateInsecure(uint256 orderId, uint8 score) external {
        Order storage o = orders[orderId];
        require(msg.sender == o.buyer, "Not buyer");
        vendorScore[o.vendor] += score;
    }

    // --- Defense: only escrow‐paid orders & one‐time rating
    function recordOrderSecure(address vendor) external returns (uint256) {
        // only callable after escrow deposit
        uint256 id = nextOrder++;
        orders[id] = Order(msg.sender, vendor, true);
        return id;
    }
    function rateSecure(uint256 orderId, uint8 score) external {
        Order storage o = orders[orderId];
        require(o.paid && msg.sender == o.buyer, "Not eligible");
        require(!rated[orderId][msg.sender], "Already rated");
        require(score <= 5, "Bad score");
        rated[orderId][msg.sender] = true;
        vendorScore[o.vendor] += score;
    }

    // batch rating with limit
    function batchRateSecure(uint256[] calldata ids, uint8[] calldata scores) external {
        require(ids.length == scores.length && ids.length <= 20, "Batch too large");
        for (uint i = 0; i < ids.length; i++) {
            rateSecure(ids[i], scores[i]);
        }
    }
}

/// 3) Anonymous Payment Pool (Mixer)
contract SilkRoadMixer is Base {
    bytes32 public merkleRoot;
    uint256 public batchSize;           // fixed deposit
    uint256 public batchDeadline;       // reveal after this
    mapping(bytes32 => bool) public nullifierUsed;

    event Deposit(bytes32 commitment);
    event Withdraw(address to, bytes32 nullifier);

    // --- Attack: withdraw without deposit or reuse nullifier
    function withdrawInsecure(bytes32 nullifier) external {
        require(!nullifierUsed[nullifier], "Already used");
        nullifierUsed[nullifier] = true;
        payable(msg.sender).transfer(batchSize);
        emit Withdraw(msg.sender, nullifier);
    }

    // --- Defense: require valid proof + nullifier tracking
    function setRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    function withdrawSecure(
        bytes calldata proof,
        bytes32 root,
        bytes32 nullifier,
        address payable recipient
    ) external nonReentrant {
        require(root == merkleRoot, "Root mismatch");
        require(!nullifierUsed[nullifier], "Nullifier used");
        require(verifyProof(proof, root, nullifier), "Invalid proof");
        nullifierUsed[nullifier] = true;
        recipient.transfer(batchSize);
        emit Withdraw(recipient, nullifier);
    }

    // Deposit a fixed amount with a commitment
    function depositSecure(bytes32 commitment) external payable {
        require(msg.value == batchSize, "Wrong amount");
        emit Deposit(commitment);
    }

    // stub verifier (integrate actual zk verifier)
    function verifyProof(bytes calldata, bytes32, bytes32) public pure returns (bool) {
        return true;
    }

    receive() external payable {}
}
