// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FHE Computation Proxy
/// @notice Accepts encrypted computation results computed off-chain via FHE and links them to original input references.

contract FHEComputeProxy {
    struct Computation {
        bytes32 resultCipher;
        string operation; // e.g., "add(2,3)", "dot product", "encrypted sum"
        string dataRef;   // e.g., IPFS hash, UUID
    }

    mapping(address => Computation[]) public computations;

    event FHEComputationUploaded(address indexed user, string operation, bytes32 result);

    function submitFHEComputation(bytes32 resultCipher, string memory operation, string memory dataRef) external {
        computations[msg.sender].push(Computation(resultCipher, operation, dataRef));
        emit FHEComputationUploaded(msg.sender, operation, resultCipher);
    }

    function getComputation(address user, uint256 index) external view returns (bytes32, string memory, string memory) {
        Computation memory c = computations[user][index];
        return (c.resultCipher, c.operation, c.dataRef);
    }
}
