// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChainReorganizationSimulator {
    address public owner;

    // Structure representing a simplified block header.
    struct BlockHeader {
        uint256 blockNumber;
        bytes32 blockHash;
    }

    // Main chain and fork chain arrays.
    BlockHeader[] public mainChain;
    BlockHeader[] public forkChain;

    event BlockAddedToMain(uint256 blockNumber, bytes32 blockHash);
    event BlockAddedToFork(uint256 blockNumber, bytes32 blockHash);
    event ChainReorganized(uint256 newLength);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Adds a new block to the main chain.
    /// @param _blockNumber The block number.
    /// @param _blockHash The hash of the block.
    function addBlockToMain(uint256 _blockNumber, bytes32 _blockHash) external onlyOwner {
        mainChain.push(BlockHeader(_blockNumber, _blockHash));
        emit BlockAddedToMain(_blockNumber, _blockHash);
    }

    /// @notice Adds a new block to the fork chain.
    /// @param _blockNumber The block number.
    /// @param _blockHash The hash of the block.
    function addBlockToFork(uint256 _blockNumber, bytes32 _blockHash) external onlyOwner {
        forkChain.push(BlockHeader(_blockNumber, _blockHash));
        emit BlockAddedToFork(_blockNumber, _blockHash);
    }

    /// @notice Reorganizes the chain by replacing the main chain with the fork chain if the fork is longer.
    /// @dev This simulates a chain reorganization.
    function reorganizeChain() external onlyOwner {
        require(forkChain.length > mainChain.length, "Fork chain is not longer than main chain");

        // Replace mainChain with forkChain
        delete mainChain;
        for (uint256 i = 0; i < forkChain.length; i++) {
            mainChain.push(forkChain[i]);
        }
        // Clear the forkChain after reorganization
        delete forkChain;

        emit ChainReorganized(mainChain.length);
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
        BlockHeader memory bh = mainChain[index];
        return (bh.blockNumber, bh.blockHash);
    }
}
