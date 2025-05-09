// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SupplyChainSuite
/// @notice Modules: ProductRegistry, TransferTracker, AuditTrail

///////////////////////////////////////////////////////////////////////////
// 1) Product Registration & Metadata
///////////////////////////////////////////////////////////////////////////
contract ProductRegistry {
    address public owner;
    uint256 public constant MAX_PRODUCTS = 1000;

    struct Product { 
        address registrant; 
        bytes32 metadataHash; 
        bool exists; 
    }
    mapping(uint256 => Product) public products;
    uint256 public productCount;

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    event ProductRegistered(uint256 indexed id, bytes32 metadataHash);
    event MetadataUpdated(uint256 indexed id, bytes32 newHash);

    constructor() { owner = msg.sender; }

    // --- Attack: anyone registers unlimited bogus products
    function registerInsecure(bytes32 metadataHash) external {
        products[productCount] = Product(msg.sender, metadataHash, true);
        emit ProductRegistered(productCount, metadataHash);
        productCount++;
    }

    // --- Defense: onlyOwner + cap + immutable metadata after registration
    function registerSecure(bytes32 metadataHash) external onlyOwner {
        require(productCount < MAX_PRODUCTS, "Max products");
        products[productCount] = Product(msg.sender, metadataHash, true);
        emit ProductRegistered(productCount, metadataHash);
        productCount++;
    }

    // --- Attack: anyone can overwrite metadata
    function updateMetadataInsecure(uint256 id, bytes32 newHash) external {
        products[id].metadataHash = newHash;
        emit MetadataUpdated(id, newHash);
    }

    // --- Defense: only original registrant or owner, immutable after lock
    mapping(uint256 => bool) public locked;
    function updateMetadataSecure(uint256 id, bytes32 newHash) external {
        Product storage p = products[id];
        require(p.exists, "No such product");
        require(!locked[id], "Locked");
        require(msg.sender == p.registrant || msg.sender == owner, "No permission");
        p.metadataHash = newHash;
        locked[id] = true;  // lock after first secure update
        emit MetadataUpdated(id, newHash);
    }
}

///////////////////////////////////////////////////////////////////////////
// 2) Ownership Transfer Tracking
///////////////////////////////////////////////////////////////////////////
contract TransferTracker is ReentrancyGuard {
    struct Ownership { address owner; uint256 nonce; }
    mapping(uint256 => Ownership) public state; // productId → Ownership

    event TransferRecorded(uint256 indexed productId, address from, address to, uint256 nonce);

    // --- Attack: anyone claims product if uninitialized
    function initInsecure(uint256 productId) external {
        state[productId] = Ownership(msg.sender, 0);
    }
    function transferInsecure(uint256 productId, address to) external {
        Ownership storage o = state[productId];
        // no ownership check, no nonce bump
        o.owner = to;
        emit TransferRecorded(productId, o.owner, to, o.nonce);
    }

    // --- Defense: require current owner + per-product nonce + CEI
    function initSecure(uint256 productId) external {
        require(state[productId].owner == address(0), "Already initialized");
        state[productId] = Ownership(msg.sender, 0);
    }
    function transferSecure(uint256 productId, address to) external nonReentrant {
        Ownership storage o = state[productId];
        require(o.owner == msg.sender, "Not current owner");
        uint256 nextNonce = o.nonce + 1;
        address from = o.owner;
        // Effects
        o.owner = to;
        o.nonce = nextNonce;
        // Interaction: emit with new nonce
        emit TransferRecorded(productId, from, to, nextNonce);
    }
}

///////////////////////////////////////////////////////////////////////////
// 3) Audit Trail Verification
///////////////////////////////////////////////////////////////////////////
contract AuditTrail {
    // checkpoint merkle root per product, monotonic
    mapping(uint256 => bytes32) public merkleRoot;
    mapping(uint256 => uint256) public checkpointNonce;

    event CheckpointSet(uint256 indexed productId, bytes32 merkleRoot, uint256 nonce);

    // --- Attack: auditor can’t verify missing on-chain data
    // (no checkpoint) ⇒ blind spot

    // --- Defense: set checkpoint after events with monotonic nonces
    function setCheckpoint(uint256 productId, bytes32 root, uint256 nonce) external {
        require(nonce > checkpointNonce[productId], "Bad nonce");
        merkleRoot[productId] = root;
        checkpointNonce[productId] = nonce;
        emit CheckpointSet(productId, root, nonce);
    }

    // off-chain auditors subscribe to CheckpointSet to verify history
}
