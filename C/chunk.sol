// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ChunkSimulator
/// @notice A simplified simulation of the "chunk" concept from NEAR protocol.
/// In NEAR, each block is divided into chunks that belong to specific shards. This simulation
/// allows the owner to add chunks, append transactions to them, and retrieve chunk data.
contract ChunkSimulator {
    address public owner;
    uint256 public nextChunkId;

    // Structure representing a chunk.
    struct Chunk {
        uint256 chunkId;         // Unique chunk identifier.
        uint256 shardId;         // Shard to which this chunk belongs.
        uint256 blockNumber;     // Block number associated with this chunk.
        bytes32 stateRoot;       // State root for validation.
        string[] transactions;   // List of transactions included in this chunk.
        uint256 timestamp;       // Timestamp when the chunk was created.
    }

    // Array to store all chunks.
    Chunk[] public chunks;

    // Events to log chunk creation and transaction additions.
    event ChunkAdded(uint256 indexed chunkId, uint256 shardId, uint256 blockNumber, bytes32 stateRoot, uint256 timestamp);
    event TransactionAdded(uint256 indexed chunkId, string transactionData);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        nextChunkId = 0;
    }

    /// @notice Adds a new chunk to the system.
    /// @param shardId The shard ID for the chunk.
    /// @param blockNumber The block number for which this chunk is created.
    /// @param stateRoot The state root of the chunk.
    function addChunk(uint256 shardId, uint256 blockNumber, bytes32 stateRoot) external onlyOwner {
        Chunk storage newChunk = chunks.push();
        newChunk.chunkId = nextChunkId;
        newChunk.shardId = shardId;
        newChunk.blockNumber = blockNumber;
        newChunk.stateRoot = stateRoot;
        newChunk.timestamp = block.timestamp;
        emit ChunkAdded(nextChunkId, shardId, blockNumber, stateRoot, block.timestamp);
        nextChunkId++;
    }

    /// @notice Adds a transaction to a specific chunk.
    /// @param chunkId The ID of the chunk.
    /// @param transactionData The transaction data (as a string) to add.
    function addTransactionToChunk(uint256 chunkId, string calldata transactionData) external onlyOwner {
        require(chunkId < nextChunkId, "Invalid chunk ID");
        chunks[chunkId].transactions.push(transactionData);
        emit TransactionAdded(chunkId, transactionData);
    }

    /// @notice Retrieves the details of a specific chunk.
    /// @param chunkId The ID of the chunk to retrieve.
    /// @return chunk The Chunk struct containing all details.
    function getChunk(uint256 chunkId) external view returns (Chunk memory chunk) {
        require(chunkId < nextChunkId, "Invalid chunk ID");
        return chunks[chunkId];
    }

    /// @notice Returns the total number of chunks stored.
    /// @return The count of chunks.
    function getChunkCount() external view returns (uint256) {
        return chunks.length;
    }
}
