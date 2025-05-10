// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TamperProofLedgerModule - Attack and Defense of Ledger Tampering in Solidity

// ==============================
// 🔓 Vulnerable Tamperable Ledger
// ==============================
contract TamperLedger {
    mapping(uint256 => string) public records;

    function write(uint256 index, string memory data) external {
        records[index] = data;
    }

    function read(uint256 index) external view returns (string memory) {
        return records[index];
    }
}

// ==============================
// 🔓 Ledger Attacker Simulation
// ==============================
interface ITamperLedger {
    function write(uint256, string calldata) external;
}

contract LedgerAttacker {
    ITamperLedger public target;

    constructor(address _ledger) {
        target = ITamperLedger(_ledger);
    }

    function overwrite(uint256 index, string calldata newData) external {
        target.write(index, newData);
    }
}

// ==============================
// 🔐 Safe Append-Only Ledger with Merkle Root
// ==============================
contract SafeTamperProofLedger {
    mapping(uint256 => bytes32) public entryHashes;
    uint256 public lastIndex;
    bool public finalized;

    event EntryAdded(uint256 indexed index, bytes32 hash);

    modifier notFinalized() {
        require(!finalized, "Ledger finalized");
        _;
    }

    function append(string memory data) external notFinalized {
        bytes32 hash = keccak256(abi.encodePacked(data, msg.sender, block.number));
        entryHashes[lastIndex] = hash;
        emit EntryAdded(lastIndex, hash);
        lastIndex++;
    }

    function finalizeLedger() external {
        finalized = true;
    }

    function getEntry(uint256 index) external view returns (bytes32) {
        return entryHashes[index];
    }

    function verifyEntry(uint256 index, string memory data, address sender, uint256 blockNum) external view returns (bool) {
        return entryHashes[index] == keccak256(abi.encodePacked(data, sender, blockNum));
    }
}

// ==============================
// 🧪 Merkle Verification Utility (Mocked Example)
// ==============================
contract MerkleUtils {
    function verify(bytes32 root, bytes32 leaf, bytes32[] calldata proof) external pure returns (bool valid) {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            hash = keccak256(abi.encodePacked(hash, proof[i]));
        }
        return hash == root;
    }

    function leafFromData(string memory data, address user, uint256 blockNumber) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(data, user, blockNumber));
    }
}
