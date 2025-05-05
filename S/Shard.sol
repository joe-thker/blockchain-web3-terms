// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShardSuite
/// @notice Implements StateShard, TxShardRouter, and CrossShardCommunicator patterns
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
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) State Shard Management
contract StateShard is Base {
    // registry of valid shard IDs
    mapping(uint256 => bool) public validShard;
    // per-shard user data
    mapping(uint256 => mapping(address => uint256)) public shardData;

    // --- Attack: anyone writes to any shard, no checks
    function writeInsecure(uint256 shardId, uint256 value) external {
        shardData[shardId][msg.sender] = value;
    }

    // --- Defense: only shard admins can write & shard must exist
    mapping(uint256 => address) public shardAdmin;
    modifier onlyShardAdmin(uint256 shardId) {
        require(shardAdmin[shardId] == msg.sender, "Not shard admin");
        _;
    }

    function registerShard(uint256 shardId, address admin) external onlyOwner {
        require(!validShard[shardId], "Already registered");
        validShard[shardId] = true;
        shardAdmin[shardId] = admin;
    }

    function writeSecure(uint256 shardId, uint256 value) external onlyShardAdmin(shardId) {
        require(validShard[shardId], "Invalid shard");
        shardData[shardId][msg.sender] = value;
    }
}

/// 2) Transaction Shard Routing
contract TxShardRouter is Base {
    struct Tx { address sender; bytes data; uint256 nonce; }
    // registry of shards
    mapping(uint256 => bool) public validShard;
    // per-shard nonce tracking
    mapping(uint256 => mapping(address => uint256)) public shardNonce;
    // store last routed tx per shard
    mapping(uint256 => Tx) public lastTx;

    // --- Attack: route any payload to any shard, no checks
    function routeInsecure(uint256 shardId, bytes calldata data) external {
        lastTx[shardId] = Tx(msg.sender, data, 0);
    }

    // --- Defense: shard must exist & nonce++, store nonce
    function registerShard(uint256 shardId) external onlyOwner {
        validShard[shardId] = true;
    }

    function routeSecure(uint256 shardId, bytes calldata data) external {
        require(validShard[shardId], "Invalid shard");
        uint256 n = ++shardNonce[shardId][msg.sender];
        lastTx[shardId] = Tx(msg.sender, data, n);
    }
}

/// 3) Cross-Shard Communication
contract CrossShardCommunicator is Base, ReentrancyGuard {
    // track processed message IDs
    mapping(bytes32 => bool) public processed;
    // on-chain shard roots for Merkle proofs
    mapping(uint256 => bytes32) public shardRoot;

    event MessageProcessed(uint256 fromShard, uint256 toShard, bytes data, bytes32 msgId);

    // --- Attack: anyone sets root & processes fake messages
    function setShardRootInsecure(uint256 shardId, bytes32 root) external {
        shardRoot[shardId] = root;
    }

    // --- Defense: onlyOwner sets root
    function setShardRootSecure(uint256 shardId, bytes32 root) external onlyOwner {
        shardRoot[shardId] = root;
    }

    // --- Attack: process without proof, no replay protection
    function processMessageInsecure(
        uint256 fromShard,
        uint256 toShard,
        bytes calldata data,
        bytes32 msgId
    ) external {
        // immediate processing
        emit MessageProcessed(fromShard, toShard, data, msgId);
    }

    // --- Defense: verify Merkle proof + prevent duplicate
    function processMessageSecure(
        uint256 fromShard,
        uint256 toShard,
        bytes calldata data,
        bytes32[] calldata proof,
        bytes32 msgId
    ) external nonReentrant {
        require(!processed[msgId], "Already processed");
        // reconstruct leaf = keccak256(msgId ∥ toShard ∥ data)
        bytes32 leaf = keccak256(abi.encodePacked(msgId, toShard, data));
        require(_verifyProof(leaf, proof, shardRoot[fromShard]), "Bad proof");
        processed[msgId] = true;
        emit MessageProcessed(fromShard, toShard, data, msgId);
    }

    function _verifyProof(
        bytes32 leaf,
        bytes32[] calldata proof,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 hash = leaf;
        for (uint i = 0; i < proof.length; i++) {
            bytes32 p = proof[i];
            // assume proof gives correct order
            hash = keccak256(abi.encodePacked(hash < p ? abi.encodePacked(hash, p) : abi.encodePacked(p, hash)));
        }
        return hash == root;
    }
}
