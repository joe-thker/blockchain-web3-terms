// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ChainReorgSimulator
/// @notice This contract simulates different types of chain reorganizations (shallow, deep, and intentional).
/// It maintains a main chain and a fork chain, and allows the owner to trigger reorgs under specific conditions.
contract ChainReorgSimulator {
    address public owner;

    // Simplified block header structure.
    struct BlockHeader {
        uint256 blockNumber;
        bytes32 blockHash;
    }

    // Main chain and fork chain arrays.
    BlockHeader[] public mainChain;
    BlockHeader[] public forkChain;

    event BlockAddedToMain(uint256 blockNumber, bytes32 blockHash);
    event BlockAddedToFork(uint256 blockNumber, bytes32 blockHash);
    event ChainReorganized(string reorgType, uint256 newMainChainLength);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Adds a new block to the main chain.
    /// @param _blockNumber The block number.
    /// @param _blockHash The block hash.
    function addBlockToMain(uint256 _blockNumber, bytes32 _blockHash) external onlyOwner {
        mainChain.push(BlockHeader(_blockNumber, _blockHash));
        emit BlockAddedToMain(_blockNumber, _blockHash);
    }

    /// @notice Adds a new block to the fork chain.
    /// @param _blockNumber The block number.
    /// @param _blockHash The block hash.
    function addBlockToFork(uint256 _blockNumber, bytes32 _blockHash) external onlyOwner {
        forkChain.push(BlockHeader(_blockNumber, _blockHash));
        emit BlockAddedToFork(_blockNumber, _blockHash);
    }

    /// @notice Simulates a shallow reorganization.
    /// Requires the fork chain to be exactly one block longer than the main chain.
    function reorganizeChainShallow() external onlyOwner {
        require(forkChain.length == mainChain.length + 1, "Fork chain must be exactly one block longer for shallow reorg");
        _applyReorganization("Shallow");
    }

    /// @notice Simulates a deep reorganization.
    /// Requires the fork chain to be at least 3 blocks longer than the main chain.
    function reorganizeChainDeep() external onlyOwner {
        require(forkChain.length >= mainChain.length + 3, "Fork chain must be at least 3 blocks longer for deep reorg");
        _applyReorganization("Deep");
    }

    /// @notice Simulates an intentional reorganization (e.g., during a protocol upgrade).
    /// The owner can set a new main chain by providing a new chain (an array of block headers).
    /// @param newChainBlockNumbers Array of new block numbers.
    /// @param newChainBlockHashes Array of new block hashes.
    function reorganizeChainIntentional(uint256[] calldata newChainBlockNumbers, bytes32[] calldata newChainBlockHashes) external onlyOwner {
        require(newChainBlockNumbers.length == newChainBlockHashes.length, "Arrays must be of equal length");
        // Replace the main chain with the provided new chain.
        delete mainChain;
        for (uint256 i = 0; i < newChainBlockNumbers.length; i++) {
            mainChain.push(BlockHeader(newChainBlockNumbers[i], newChainBlockHashes[i]));
        }
        // Clear the fork chain.
        delete forkChain;
        emit ChainReorganized("Intentional", mainChain.length);
    }

    /// @notice Internal function that applies reorganization by replacing the main chain with the fork chain.
    /// @param reorgType A string indicating the type of reorg ("Shallow" or "Deep").
    function _applyReorganization(string memory reorgType) internal {
        delete mainChain;
        for (uint256 i = 0; i < forkChain.length; i++) {
            mainChain.push(forkChain[i]);
        }
        // Clear the fork chain.
        delete forkChain;
        emit ChainReorganized(reorgType, mainChain.length);
    }

    /// @notice Returns the length of the main chain.
    /// @return The number of blocks in the main chain.
    function getMainChainLength() external view returns (uint256) {
        return mainChain.length;
    }

    /// @notice Retrieves a block header from the main chain by index.
    /// @param index The index of the block header.
    /// @return blockNumber The block's number.
    /// @return blockHash The block's hash.
    function getMainChainBlock(uint256 index) external view returns (uint256 blockNumber, bytes32 blockHash) {
        require(index < mainChain.length, "Index out of bounds");
        BlockHeader memory header = mainChain[index];
        return (header.blockNumber, header.blockHash);
    }

    /// @notice Returns the length of the fork chain.
    /// @return The number of blocks in the fork chain.
    function getForkChainLength() external view returns (uint256) {
        return forkChain.length;
    }
}
