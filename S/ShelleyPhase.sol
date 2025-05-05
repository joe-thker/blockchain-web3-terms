// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShelleyPhaseSuite
/// @notice Implements StakeDelegation, PoolRegistry, and RewardDistributor patterns
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

/// 1) Stake Delegation
contract StakeDelegation is Base, ReentrancyGuard {
    mapping(address => address)   public delegation;      // user → pool
    mapping(address => uint256)   public delegatedAmt;   // user → amount

    uint256 public changeDelay = 1 hours;
    mapping(address => uint256) public lastChange;       // user → timestamp

    // --- Attack: immediate re-delegation with no checks
    function delegateInsecure(address pool) external payable {
        delegation[msg.sender]    = pool;
        delegatedAmt[msg.sender] += msg.value;
    }

    // --- Defense: whitelist pool + time-delay + CEI
    mapping(address => bool) public approvedPool;
    function approvePool(address pool) external onlyOwner {
        approvedPool[pool] = true;
    }

    function delegateSecure(address pool) external payable nonReentrant {
        require(approvedPool[pool], "Pool not approved");
        uint256 nextAllowed = lastChange[msg.sender] + changeDelay;
        require(block.timestamp >= nextAllowed, "Change too soon");
        // Effects
        delegatedAmt[msg.sender] += msg.value;
        delegation[msg.sender]   = pool;
        lastChange[msg.sender] = block.timestamp;
    }
}

/// 2) Stake Pool Registration
contract PoolRegistry is Base {
    struct PoolInfo {
        uint256 pledge;
        uint256 cost;
        uint256 marginBP;    // basis points
        bool    active;
    }
    mapping(address => PoolInfo) public pools;

    uint256 public minPledge = 1000 ether;
    uint256 public maxMargin = 5000;  // 50%

    // --- Attack: register with fake/faulty metadata
    function registerPoolInsecure(
        address pool,
        uint256 pledge,
        uint256 cost,
        uint256 marginBP
    ) external {
        pools[pool] = PoolInfo(pledge, cost, marginBP, true);
    }

    // --- Defense: enforce schema + deposit + signature proof
    function registerPoolSecure(
        address pool,
        uint256 pledge,
        uint256 cost,
        uint256 marginBP,
        bytes calldata metadataSig
    ) external payable {
        // require stake deposit equal to pledge
        require(msg.value == pledge, "Incorrect pledge deposit");
        require(pledge >= minPledge, "Pledge too low");
        require(marginBP <= maxMargin,  "Margin too high");
        // verify off-chain signed metadata
        bytes32 h = keccak256(abi.encodePacked(pool, pledge, cost, marginBP));
        require(_verifySig(h, metadataSig), "Bad metadata sig");
        pools[pool] = PoolInfo(pledge, cost, marginBP, true);
    }

    function _verifySig(bytes32 hash, bytes memory sig) internal view returns (bool) {
        // Simplified: recover owner
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(sig, (bytes32, bytes32, uint8));
        address signer = ecrecover(ethHash, v, r, s);
        return signer == owner;
    }
}

/// 3) Reward Distribution
contract RewardDistributor is Base, ReentrancyGuard {
    mapping(address => uint256) public rewards;     // user → owed reward
    uint256 public batchLimit = 100;

    // --- Attack: unbounded loop causing OOG
    function distributeInsecure(address[] calldata users, uint256[] calldata amounts) external {
        for (uint i = 0; i < users.length; i++) {
            rewards[users[i]] += amounts[i];
        }
    }

    // --- Defense: batch limits + bounds checks
    function distributeSecure(
        address[] calldata users,
        uint256[] calldata amounts
    ) external onlyOwner {
        uint len = users.length;
        require(len == amounts.length, "Length mismatch");
        require(len <= batchLimit,   "Batch too large");
        for (uint i = 0; i < len; i++) {
            uint256 amt = amounts[i];
            require(amt > 0, "Zero amount");
            rewards[users[i]] += amt;
        }
    }

    // --- Attack: withdraw any amount or others’ rewards
    function withdrawInsecure(uint256 amount) external {
        require(rewards[msg.sender] >= amount, "Insufficient");
        payable(msg.sender).transfer(amount);
    }

    // --- Defense: CEI + correct balance update
    function withdrawSecure(uint256 amount) external nonReentrant {
        uint256 bal = rewards[msg.sender];
        require(bal >= amount, "Insufficient");
        rewards[msg.sender] = bal - amount;
        (bool ok, ) = payable(msg.sender).call{ value: amount, gas: 2300 }("");
        require(ok, "Transfer failed");
    }

    // Fund contract
    receive() external payable {}
}
