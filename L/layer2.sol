// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Layer 2 Commit Simulator
/// @notice Mimics an L2 posting transaction batches to L1
contract L2CommitSimulator {
    address public operator;
    uint256 public batchId;
    mapping(uint256 => bytes32) public batchRoots;

    event BatchCommitted(uint256 batchId, bytes32 merkleRoot);

    modifier onlyOperator() {
        require(msg.sender == operator, "Not L2 operator");
        _;
    }

    constructor(address _operator) {
        operator = _operator;
    }

    /// @notice Submit a new batch (e.g., zk or optimistic rollup state)
    function submitBatch(bytes32 _merkleRoot) external onlyOperator {
        batchRoots[batchId] = _merkleRoot;
        emit BatchCommitted(batchId, _merkleRoot);
        batchId++;
    }

    /// @notice Verify if a given root has been committed
    function isBatchSubmitted(uint256 _id) external view returns (bool) {
        return batchRoots[_id] != bytes32(0);
    }
}
