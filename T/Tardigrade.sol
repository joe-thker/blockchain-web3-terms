// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TardigradeModule - Simulated Resilient Storage System (Tardigrade Style) with Attack and Defense

// ==============================
// 🔓 Insecure Resilient Storage
// ==============================
contract TardigradeStorage {
    struct Shard {
        bytes data;
        uint256 timestamp;
    }

    mapping(bytes32 => Shard[]) public fileShards; // fileId => shard list

    event ShardAdded(bytes32 indexed fileId, uint256 shardIndex);

    function storeShard(bytes32 fileId, bytes calldata data) external {
        fileShards[fileId].push(Shard(data, block.timestamp));
        emit ShardAdded(fileId, fileShards[fileId].length - 1);
    }

    function getShard(bytes32 fileId, uint256 index) external view returns (bytes memory) {
        return fileShards[fileId][index].data;
    }
}

// ==============================
// 🔓 Attack: Poisoned Shard Injection
// ==============================
interface ITardigradeStorage {
    function storeShard(bytes32 fileId, bytes calldata data) external;
}

contract StorageAttacker {
    ITardigradeStorage public target;

    constructor(address _target) {
        target = ITardigradeStorage(_target);
    }

    function injectPoison(bytes32 fileId) external {
        bytes memory garbage = hex"deadbeefcafebabe";
        target.storeShard(fileId, garbage);
    }
}

// ==============================
// 🔐 Hardened Tardigrade Storage
// ==============================
contract SafeTardigradeStorage {
    struct VerifiedShard {
        bytes data;
        bytes32 hash;
        address signer;
        uint256 timestamp;
    }

    mapping(bytes32 => VerifiedShard[]) public verifiedFiles;

    event VerifiedShardStored(bytes32 indexed fileId, uint256 index, address signer);

    function storeVerifiedShard(bytes32 fileId, bytes calldata data, bytes32 hash, address signer) external {
        require(keccak256(data) == hash, "Hash mismatch");
        verifiedFiles[fileId].push(VerifiedShard(data, hash, signer, block.timestamp));
        emit VerifiedShardStored(fileId, verifiedFiles[fileId].length - 1, signer);
    }

    function getVerifiedShard(bytes32 fileId, uint256 index) external view returns (bytes memory, address) {
        VerifiedShard memory s = verifiedFiles[fileId][index];
        return (s.data, s.signer);
    }
}

// ==============================
// 🧪 Shard Hash Utility
// ==============================
contract ShardUtils {
    function computeHash(bytes memory data) external pure returns (bytes32) {
        return keccak256(data);
    }

    function signHash(bytes32 hash, address signer) external pure returns (bytes32) {
        // Simplified signer context commitment (mock)
        return keccak256(abi.encodePacked(signer, hash));
    }
}
