// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShardingSuite
/// @notice Implements StateSharding, TxSharding, and ShardRebalance modules
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _lock;
    modifier nonReentrant() {
        require(!_lock, "Reentrant");
        _lock = true;
        _;
        _lock = false;
    }
}

/// 1) State Sharding
contract StateSharding is Base {
    // registry of valid shard IDs → admin
    mapping(uint256 => address) public shardAdmin;
    mapping(uint256 => bool)    public validShard;
    // per-shard user balances
    mapping(uint256 => mapping(address => uint256)) public shardBalances;

    // --- Attack: anyone writes any shard
    function writeInsecure(uint256 shardId, uint256 amount) external {
        shardBalances[shardId][msg.sender] = amount;
    }

    // --- Defense: shard must exist & only admin writes
    modifier onlyShardAdmin(uint256 shardId) {
        require(validShard[shardId], "Bad shard");
        require(msg.sender == shardAdmin[shardId], "Not shard admin");
        _;
    }

    function registerShard(uint256 shardId, address admin) external onlyOwner {
        require(!validShard[shardId], "Already exists");
        validShard[shardId] = true;
        shardAdmin[shardId] = admin;
    }

    function writeSecure(uint256 shardId, address user, uint256 amount)
        external onlyShardAdmin(shardId)
    {
        shardBalances[shardId][user] = amount;
    }
}

/// 2) Transaction Sharding
contract TxSharding is Base {
    // registry of allowed shards
    mapping(uint256 => bool) public validShard;
    // per-shard nonces
    mapping(uint256 => mapping(address => uint256)) public shardNonce;
    // last routed TX
    struct Routed { address sender; bytes data; uint256 nonce; }
    mapping(uint256 => Routed) public lastRouted;

    // --- Attack: no shard check, no nonce
    function routeInsecure(uint256 shardId, bytes calldata data) external {
        lastRouted[shardId] = Routed(msg.sender, data, 0);
    }

    // --- Defense: require valid shard & bump nonce
    function registerShard(uint256 shardId) external onlyOwner {
        validShard[shardId] = true;
    }

    function routeSecure(uint256 shardId, bytes calldata data) external {
        require(validShard[shardId], "Invalid shard");
        uint256 n = ++shardNonce[shardId][msg.sender];
        lastRouted[shardId] = Routed(msg.sender, data, n);
    }
}

/// 3) Shard Rebalancing
contract ShardRebalance is Base, ReentrancyGuard {
    // track processed rebalance IDs
    mapping(bytes32 => bool) public processed;
    // simple balance pools per shard
    mapping(uint256 => uint256) public shardPool;

    event RebalanceExecuted(uint256 fromShard, uint256 toShard, uint256 amount, bytes32 id);

    // seed pools
    function seedPool(uint256 shardId, uint256 amount) external onlyOwner {
        shardPool[shardId] = amount;
    }

    // --- Attack: anyone rebalance, no checks
    function rebalanceInsecure(
        uint256 fromShard,
        uint256 toShard,
        uint256 amount,
        bytes32 id
    ) external {
        require(shardPool[fromShard] >= amount, "Underflow");
        shardPool[fromShard] -= amount;
        shardPool[toShard]   += amount;
        emit RebalanceExecuted(fromShard, toShard, amount, id);
    }

    // --- Defense: onlyOwner + unique ID + atomic CEI
    function rebalanceSecure(
        uint256 fromShard,
        uint256 toShard,
        uint256 amount,
        bytes32 id
    ) external onlyOwner nonReentrant {
        require(!processed[id], "Replayed");
        require(shardPool[fromShard] >= amount, "Underflow");
        // Effects
        processed[id]      = true;
        shardPool[fromShard] -= amount;
        shardPool[toShard]   += amount;
        // Interaction via event for off-chain verification
        emit RebalanceExecuted(fromShard, toShard, amount, id);
    }
}
