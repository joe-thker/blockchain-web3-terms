// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ChainSplitSimulator
/// @notice This contract simulates a chain split by maintaining a main chain and two forked branches.
/// The owner can add blocks to the main chain before a split. Once a split is triggered, the main chain is copied
/// to Branch A and Branch B, and new blocks can be added to each branch independently.
contract ChainSplitSimulator {
    address public owner;
    bool public splitOccurred;

    // Simplified block header structure.
    struct BlockHeader {
        uint256 blockNumber;
        bytes32 blockHash;
    }

    // Pre-split main chain.
    BlockHeader[] public mainChain;
    // Fork branches created after a chain split.
    BlockHeader[] public branchA;
    BlockHeader[] public branchB;

    event BlockAddedToMain(uint256 blockNumber, bytes32 blockHash);
    event ChainSplit(uint256 mainChainLength);
    event BlockAddedToBranchA(uint256 blockNumber, bytes32 blockHash);
    event BlockAddedToBranchB(uint256 blockNumber, bytes32 blockHash);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        splitOccurred = false;
    }

    /// @notice Adds a block to the main chain before the split.
    /// @param _blockNumber The block number.
    /// @param _blockHash The block hash.
    function addBlockToMain(uint256 _blockNumber, bytes32 _blockHash) external onlyOwner {
        require(!splitOccurred, "Chain already split");
        mainChain.push(BlockHeader(_blockNumber, _blockHash));
        emit BlockAddedToMain(_blockNumber, _blockHash);
    }

    /// @notice Triggers a chain split by copying the main chain to two separate branches.
    function splitChain() external onlyOwner {
        require(!splitOccurred, "Chain already split");
        for (uint256 i = 0; i < mainChain.length; i++) {
            branchA.push(mainChain[i]);
            branchB.push(mainChain[i]);
        }
        splitOccurred = true;
        emit ChainSplit(mainChain.length);
    }

    /// @notice Adds a block to Branch A after the split.
    /// @param _blockNumber The block number.
    /// @param _blockHash The block hash.
    function addBlockToBranchA(uint256 _blockNumber, bytes32 _blockHash) external onlyOwner {
        require(splitOccurred, "Chain not split yet");
        branchA.push(BlockHeader(_blockNumber, _blockHash));
        emit BlockAddedToBranchA(_blockNumber, _blockHash);
    }

    /// @notice Adds a block to Branch B after the split.
    /// @param _blockNumber The block number.
    /// @param _blockHash The block hash.
    function addBlockToBranchB(uint256 _blockNumber, bytes32 _blockHash) external onlyOwner {
        require(splitOccurred, "Chain not split yet");
        branchB.push(BlockHeader(_blockNumber, _blockHash));
        emit BlockAddedToBranchB(_blockNumber, _blockHash);
    }

    /// @notice Returns the length of the main chain.
    /// @return The number of blocks in the main chain.
    function getMainChainLength() external view returns (uint256) {
        return mainChain.length;
    }

    /// @notice Returns the length of Branch A.
    /// @return The number of blocks in Branch A.
    function getBranchALength() external view returns (uint256) {
        return branchA.length;
    }

    /// @notice Returns the length of Branch B.
    /// @return The number of blocks in Branch B.
    function getBranchBLength() external view returns (uint256) {
        return branchB.length;
    }

    /// @notice Retrieves a block header from Branch A.
    /// @param index The index of the block in Branch A.
    /// @return blockNumber The block's number.
    /// @return blockHash The block's hash.
    function getBranchABlock(uint256 index) external view returns (uint256 blockNumber, bytes32 blockHash) {
        require(index < branchA.length, "Index out of bounds");
        BlockHeader memory header = branchA[index];
        return (header.blockNumber, header.blockHash);
    }

    /// @notice Retrieves a block header from Branch B.
    /// @param index The index of the block in Branch B.
    /// @return blockNumber The block's number.
    /// @return blockHash The block's hash.
    function getBranchBBlock(uint256 index) external view returns (uint256 blockNumber, bytes32 blockHash) {
        require(index < branchB.length, "Index out of bounds");
        BlockHeader memory header = branchB[index];
        return (header.blockNumber, header.blockHash);
    }
}
