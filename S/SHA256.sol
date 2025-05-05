// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SHA256Suite
/// @notice Implements Hash Registry, Commit–Reveal, and Merkle Proof Verification using SHA-256
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// 1) Hash Registry
contract HashRegistry is Base {
    mapping(bytes32 => bool) public registered;

    // --- Attack: anyone can register duplicates or malicious hashes
    function registerInsecure(bytes32 hash) external {
        registered[hash] = true;
    }

    // --- Defense: onlyOwner + uniqueness + nonzero
    function registerSecure(bytes32 hash) external onlyOwner {
        require(hash != bytes32(0), "Zero hash");
        require(!registered[hash], "Already registered");
        registered[hash] = true;
    }
}

/// 2) Commit–Reveal Scheme
contract CommitReveal is Base {
    struct CommitInfo { bytes32 commitment; uint timestamp; bool revealed; }
    mapping(address => CommitInfo) public commits;
    uint public revealDeadline = 1 hours;

    // --- Attack: commit without deadline or salt, anyone can override
    function commitInsecure(bytes32 commitment) external {
        commits[msg.sender] = CommitInfo(commitment, block.timestamp, false);
    }

    // --- Defense: salted commitment + single use
    function commitSecure(bytes32 commitment) external {
        require(commits[msg.sender].commitment == bytes32(0), "Already committed");
        // salt = keccak256(commitment ∥ sender)
        commits[msg.sender] = CommitInfo(keccak256(abi.encodePacked(commitment, msg.sender)), block.timestamp, false);
    }

    // --- Attack: reveal anytime, anyone could call if they know preimage
    function revealInsecure(bytes32 secret) external view returns (bool) {
        return sha256(abi.encodePacked(secret)) == commits[msg.sender].commitment;
    }

    // --- Defense: enforce deadline, validate sender & salt
    function revealSecure(bytes32 secret) external returns (bool) {
        CommitInfo storage info = commits[msg.sender];
        require(info.commitment != bytes32(0), "No commit");
        require(!info.revealed, "Already revealed");
        require(block.timestamp <= info.timestamp + revealDeadline, "Deadline passed");
        // recompute salted hash
        bytes32 expected = sha256(abi.encodePacked(secret, msg.sender));
        require(expected == info.commitment, "Bad secret");
        info.revealed = true;
        return true;
    }
}

/// 3) Merkle Proof Verification
contract MerkleVerifier is Base {
    bytes32 public merkleRoot;

    // --- Attack: anyone can replace root, proof order ignored
    function setRootInsecure(bytes32 root) external {
        merkleRoot = root;
    }

    // --- Defense: onlyOwner + require nonzero
    function setRootSecure(bytes32 root) external onlyOwner {
        require(root != bytes32(0), "Zero root");
        merkleRoot = root;
    }

    // --- Attack: naive proof validation (always left‐concat)
    function verifyInsecure(bytes32 leaf, bytes32[] calldata proof) external view returns (bool) {
        bytes32 hash = leaf;
        for (uint i = 0; i < proof.length; i++) {
            hash = sha256(abi.encodePacked(hash, proof[i]));
        }
        return hash == merkleRoot;
    }

    // --- Defense: sorted-pair hashing + proof length limit
    function verifySecure(bytes32 leaf, bytes32[] calldata proof) external view returns (bool) {
        require(proof.length > 0 && proof.length <= 256, "Bad proof length");
        bytes32 hash = leaf;
        for (uint i = 0; i < proof.length; i++) {
            bytes32 el = proof[i];
            // enforce sorted order to prevent invalid pairings
            if (hash < el) {
                hash = sha256(abi.encodePacked(hash, el));
            } else {
                hash = sha256(abi.encodePacked(el, hash));
            }
        }
        return hash == merkleRoot;
    }
}
