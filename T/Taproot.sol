// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TaprootModule - Simulated Taproot/Merkle Execution with Attack and Defense in Solidity

// ==============================
// 🔐 Merkleized Execution Tree (Taproot MAST)
// ==============================
contract TaprootCommitTree {
    bytes32 public root;
    mapping(bytes32 => bool) public executedBranches;

    constructor(bytes32 _root) {
        root = _root;
    }

    function execute(bytes32[] calldata proof, bytes memory branchData, uint256 value) external {
        require(!executedBranches[keccak256(branchData)], "Already executed");
        require(verifyProof(proof, keccak256(branchData)), "Invalid branch proof");

        executedBranches[keccak256(branchData)] = true;

        // Decode execution logic from branch data (simplified)
        (address target, bytes memory callData) = abi.decode(branchData, (address, bytes));
        (bool success, ) = target.call{value: value}(callData);
        require(success, "Execution failed");
    }

    function verifyProof(bytes32[] calldata proof, bytes32 leaf) public view returns (bool) {
        bytes32 computed = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computed = keccak256(abi.encodePacked(computed, proof[i]));
        }
        return computed == root;
    }

    receive() external payable {}
}

// ==============================
// 🔓 Attacker: Forge Invalid Path or Logic
// ==============================
contract TaprootAttacker {
    TaprootCommitTree public tree;

    constructor(address _tree) {
        tree = TaprootCommitTree(_tree);
    }

    function forgePath(address fakeTarget, bytes memory fakeCall, bytes32[] calldata fakeProof, uint256 value) external {
        bytes memory badBranch = abi.encode(fakeTarget, fakeCall);
        tree.execute(fakeProof, badBranch, value); // Attempt invalid execution
    }
}

// ==============================
// 🔐 Schnorr Signature Verifier (Mocked)
// ==============================
contract SchnorrVerifier {
    // Very simplified - just hashes the message and compares
    function verify(bytes32 pubkey, bytes32 r, uint256 s, bytes memory msgData) external pure returns (bool) {
        return keccak256(abi.encodePacked(pubkey, s, msgData)) == r;
    }

    function getMessageHash(bytes memory msgData) external pure returns (bytes32) {
        return keccak256(msgData);
    }
}
