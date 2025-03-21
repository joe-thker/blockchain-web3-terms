// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockInfo
/// @notice A contract that provides information about the current block.
contract BlockInfo {
    
    /// @notice Returns key information about the current block.
    /// @return blockNumber The current block number.
    /// @return blockTimestamp The timestamp of the current block.
    /// @return blockDifficulty The difficulty of the current block.
    /// @return miner The address of the miner (coinbase) for the current block.
    /// @return gasLimit The gas limit of the current block.
    function getBlockInfo() external view returns (
        uint256 blockNumber,
        uint256 blockTimestamp,
        uint256 blockDifficulty,
        address miner,
        uint256 gasLimit
    ) {
        blockNumber = block.number;
        blockTimestamp = block.timestamp;
        blockDifficulty = block.difficulty;
        miner = block.coinbase;
        gasLimit = block.gaslimit;
    }
}
