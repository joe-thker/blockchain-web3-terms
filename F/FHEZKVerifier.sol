// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FHE-ZK Verifier Simulation
/// @notice Stores encrypted result and ZK proof hash for off-chain verification

contract FHEZKVerifier {
    struct VerifiedResult {
        bytes32 encryptedResult;
        bytes32 zkProofHash; // off-chain zk proof hash
        string note;
    }

    mapping(address => VerifiedResult[]) public results;

    event EncryptedResultWithZK(address indexed user, string note);

    function submitResultWithZK(bytes32 cipher, bytes32 proofHash, string calldata note) external {
        results[msg.sender].push(VerifiedResult(cipher, proofHash, note));
        emit EncryptedResultWithZK(msg.sender, note);
    }

    function getResult(address user, uint256 index) external view returns (bytes32, bytes32, string memory) {
        VerifiedResult memory r = results[user][index];
        return (r.encryptedResult, r.zkProofHash, r.note);
    }
}
