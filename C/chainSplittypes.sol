// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ChainSplitTypesSimulator
/// @notice This contract simulates three types of chain splits: Soft Fork, Hard Fork, and Accidental Fork.
/// The owner can add blocks to the main chain, then trigger different fork types.
contract ChainSplitTypesSimulator {
    address public owner;

    // Simplified block header structure.
    struct BlockHeader {
        uint256 blockNumber;
        bytes32 blockHash;
    }

    // The main chain (pre-split).
    BlockHeader[] public mainChain;
    // Fork arrays.
    BlockHeader[] public softForkChain;
    BlockHeader[] public hardForkChain;
    BlockHeader[] public accidentalForkChain;

    event BlockAddedToMain(uint256 blockNumber, bytes32 blockHash);
    event SoftForkTriggered(uint256 mainChainLength);
    event HardForkTriggered(uint256 divergenceIndex, uint256 newHardForkLength);
    event AccidentalForkTriggered(uint256 newAccidentalForkLength);

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

    /// @notice Triggers a soft fork by copying the entire main chain to softForkChain.
    function triggerSoftFork() external onlyOwner {
        // Clear previous soft fork chain.
        delete softForkChain;
        for (uint256 i = 0; i < mainChain.length; i++) {
            softForkChain.push(mainChain[i]);
        }
        emit SoftForkTriggered(mainChain.length);
    }

    /// @notice Triggers a hard fork starting from a divergence point.
    /// The main chain is copied up to (and including) the divergence index,
    /// then new blocks are appended to simulate a new chain history.
    /// @param divergenceIndex The index at which the hard fork diverges.
    function triggerHardFork(uint256 divergenceIndex) external onlyOwner {
        require(divergenceIndex < mainChain.length, "Invalid divergence index");
        // Clear previous hard fork chain.
        delete hardForkChain;
        // Copy mainChain blocks up to divergenceIndex.
        for (uint256 i = 0; i <= divergenceIndex; i++) {
            hardForkChain.push(mainChain[i]);
        }
        // Append new blocks to simulate divergence. For simplicity, we add one new block.
        uint256 newBlockNumber = mainChain[divergenceIndex].blockNumber + 1;
        bytes32 newBlockHash = keccak256(abi.encodePacked(newBlockNumber, "hard fork"));
        hardForkChain.push(BlockHeader(newBlockNumber, newBlockHash));
        emit HardForkTriggered(divergenceIndex, hardForkChain.length);
    }

    /// @notice Triggers an accidental fork by copying the main chain and appending one extra block.
    function triggerAccidentalFork() external onlyOwner {
        // Clear previous accidental fork chain.
        delete accidentalForkChain;
        for (uint256 i = 0; i < mainChain.length; i++) {
            accidentalForkChain.push(mainChain[i]);
        }
        // Append one extra block to simulate an accidental fork.
        uint256 newBlockNumber = mainChain[mainChain.length - 1].blockNumber + 1;
        bytes32 newBlockHash = keccak256(abi.encodePacked(newBlockNumber, "accidental fork"));
        accidentalForkChain.push(BlockHeader(newBlockNumber, newBlockHash));
        emit AccidentalForkTriggered(accidentalForkChain.length);
    }

    /// @notice Returns the length of the main chain.
    function getMainChainLength() external view returns (uint256) {
        return mainChain.length;
    }

    /// @notice Returns the length of the soft fork chain.
    function getSoftForkLength() external view returns (uint256) {
        return softForkChain.length;
    }

    /// @notice Returns the length of the hard fork chain.
    function getHardForkLength() external view returns (uint256) {
        return hardForkChain.length;
    }

    /// @notice Returns the length of the accidental fork chain.
    function getAccidentalForkLength() external view returns (uint256) {
        return accidentalForkChain.length;
    }

    /// @notice Retrieves a block header from the main chain by index.
    function getMainChainBlock(uint256 index) external view returns (uint256 blockNumber, bytes32 blockHash) {
        require(index < mainChain.length, "Index out of bounds");
        BlockHeader memory bh = mainChain[index];
        return (bh.blockNumber, bh.blockHash);
    }
    
    /// @notice Retrieves a block header from the hard fork chain by index.
    function getHardForkBlock(uint256 index) external view returns (uint256 blockNumber, bytes32 blockHash) {
        require(index < hardForkChain.length, "Index out of bounds");
        BlockHeader memory bh = hardForkChain[index];
        return (bh.blockNumber, bh.blockHash);
    }
    
    /// @notice Retrieves a block header from the accidental fork chain by index.
    function getAccidentalForkBlock(uint256 index) external view returns (uint256 blockNumber, bytes32 blockHash) {
        require(index < accidentalForkChain.length, "Index out of bounds");
        BlockHeader memory bh = accidentalForkChain[index];
        return (bh.blockNumber, bh.blockHash);
    }
}
