// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FusionRollup {
    address public operator;
    uint256 public challengePeriod = 1 days;

    struct Batch {
        bytes32 dataRoot;       // Merkle root or blob hash
        uint256 timestamp;      // When the batch was submitted
        bool challenged;
        bool finalized;
    }

    uint256 public latestBatchId;
    mapping(uint256 => Batch) public batches;

    event BatchSubmitted(uint256 indexed batchId, bytes32 dataRoot);
    event BatchChallenged(uint256 indexed batchId, address challenger);
    event BatchFinalized(uint256 indexed batchId);

    modifier onlyOperator() {
        require(msg.sender == operator, "Not operator");
        _;
    }

    constructor(address _operator) {
        operator = _operator;
    }

    /// @notice Submit off-chain batch root (e.g., Merkle root or IPFS hash)
    function submitBatch(bytes32 dataRoot) external onlyOperator {
        latestBatchId++;
        batches[latestBatchId] = Batch({
            dataRoot: dataRoot,
            timestamp: block.timestamp,
            challenged: false,
            finalized: false
        });
        emit BatchSubmitted(latestBatchId, dataRoot);
    }

    /// @notice Challenge within window (fraud proof off-chain assumed)
    function challengeBatch(uint256 batchId) external {
        Batch storage batch = batches[batchId];
        require(batch.timestamp != 0, "Batch not found");
        require(block.timestamp < batch.timestamp + challengePeriod, "Too late");
        require(!batch.challenged, "Already challenged");

        batch.challenged = true;
        emit BatchChallenged(batchId, msg.sender);
    }

    /// @notice Finalize a batch after challenge period passes
    function finalizeBatch(uint256 batchId) external {
        Batch storage batch = batches[batchId];
        require(batch.timestamp != 0, "Invalid batch");
        require(!batch.finalized, "Already finalized");
        require(!batch.challenged, "Challenged batch");
        require(block.timestamp >= batch.timestamp + challengePeriod, "Challenge period not over");

        batch.finalized = true;
        emit BatchFinalized(batchId);
    }

    function isFinalized(uint256 batchId) external view returns (bool) {
        return batches[batchId].finalized;
    }
}
