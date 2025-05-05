// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SettlementSuite
/// @notice Implements Immediate, Deferred Net, and Atomic Cross-Chain Settlements
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Immediate Settlement
contract ImmediateSettlement is Base, ReentrancyGuard {
    mapping(address => uint) public balances;

    constructor() payable {
        // seed contract with liquidity
    }

    // --- Attack: naive send allows reentrancy & no CEI
    function settleInsecure(address payable to, uint amount) external {
        require(balances[msg.sender] >= amount, "Insufficient");
        // send with full gas; no CEI
        balances[msg.sender] -= amount;
        to.call{ value: amount }(""); // vulnerability
    }

    // --- Defense: CEI + reentrancy guard + limited gas
    function settleSecure(address payable to, uint amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient");
        // Effects
        balances[msg.sender] -= amount;
        // Interactions with gas stipend
        (bool ok,) = to.call{ value: amount, gas: 2300 }("");
        require(ok, "Transfer failed");
    }

    // deposit funds
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
}

/// 2) Deferred Net Settlement
contract DeferredNetSettlement is Base {
    struct Obligation {
        address participant;
        int    amount;      // positive = credit, negative = debit
    }
    Obligation[] public batch;
    mapping(address => bool) public included;
    bytes32 public merkleRoot;
    uint public freezeUntil;

    // --- Attack: add obligations without proof
    function addObligationInsecure(address participant, int amount) external {
        batch.push(Obligation(participant, amount));
    }

    // --- Defense: require Merkle‐proof and signed commitment
    function addObligationSecure(
        address participant,
        int amount,
        bytes32[] calldata proof
    ) external onlyOwner {
        // verify inclusion via Merkle‐proof
        bytes32 leaf = keccak256(abi.encodePacked(participant, amount));
        require(_verifyProof(leaf, proof), "Invalid proof");
        batch.push(Obligation(participant, amount));
    }

    // net and settle after freeze
    function settleBatchSecure() external onlyOwner {
        require(block.timestamp >= freezeUntil, "Still frozen");
        // netting
        mapping(address => int) memory net;
        for (uint i = 0; i < batch.length; i++) {
            net[batch[i].participant] += batch[i].amount;
        }
        // effectuate payouts (omitted: actual transfers)
        delete batch;
    }

    function _verifyProof(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 hash = leaf;
        for (uint i = 0; i < proof.length; i++) {
            hash = keccak256(abi.encodePacked(hash, proof[i]));
        }
        return hash == merkleRoot;
    }

    // set freeze window & root
    function configure(uint _freezeUntil, bytes32 _root) external onlyOwner {
        freezeUntil = _freezeUntil;
        merkleRoot  = _root;
    }
}

/// 3) Atomic Cross-Chain Settlement (HTLC style)
contract AtomicSettlement is Base {
    struct HTLC {
        address payable sender;
        address payable receiver;
        uint    amount;
        bytes32 hashlock;
        uint    timelock;
        bool    withdrawn;
        bool    refunded;
    }
    uint public nextId;
    mapping(uint => HTLC) public htlcs;

    // --- Attack: create without hashlock checks
    function newHTLCInsecure(
        address payable receiver,
        uint amount,
        bytes32 hashlock,
        uint timelock
    ) external payable {
        require(msg.value == amount, "Wrong amt");
        htlcs[nextId++] = HTLC(payable(msg.sender), receiver, amount, hashlock, timelock, false, false);
    }

    // --- Defense: validate parameters
    function newHTLCSecure(
        address payable receiver,
        bytes32 hashlock,
        uint timelock
    ) external payable {
        require(msg.value > 0, "Zero amount");
        require(receiver != address(0), "Invalid receiver");
        require(hashlock != bytes32(0), "Invalid hashlock");
        require(timelock > block.timestamp, "Timelock too soon");
        htlcs[nextId++] = HTLC(payable(msg.sender), receiver, msg.value, hashlock, timelock, false, false);
    }

    // receiver claims with preimage
    function withdraw(uint id, bytes32 preimage) external {
        HTLC storage h = htlcs[id];
        require(!h.withdrawn && !h.refunded, "Already used");
        require(keccak256(abi.encodePacked(preimage)) == h.hashlock, "Bad preimage");
        require(msg.sender == h.receiver, "Not receiver");
        h.withdrawn = true;
        h.receiver.transfer(h.amount);
    }

    // sender refunds after timelock
    function refund(uint id) external {
        HTLC storage h = htlcs[id];
        require(!h.withdrawn && !h.refunded, "Already used");
        require(block.timestamp >= h.timelock, "Timelock");
        require(msg.sender == h.sender, "Not sender");
        h.refunded = true;
        h.sender.transfer(h.amount);
    }
}
