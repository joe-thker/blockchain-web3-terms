// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockHeaderInfo {
    // Define a struct to represent key elements of a block header.
    struct BlockHeader {
        uint256 number;       // Block number
        uint256 timestamp;    // Block timestamp
        uint256 difficulty;   // Block difficulty
        address miner;        // Miner (coinbase) address
        uint256 gasLimit;     // Block gas limit
    }
    
    /// @notice Returns the current block header information.
    /// @return header A struct containing the current block header details.
    function getBlockHeader() external view returns (BlockHeader memory header) {
        header.number = block.number;
        header.timestamp = block.timestamp;
        header.difficulty = block.difficulty;
        header.miner = block.coinbase;
        header.gasLimit = block.gaslimit;
    }
}
