// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockExplorer
/// @notice A simple contract to retrieve block information. 
/// This can serve as a building block for a blockchain explorer application.
contract BlockExplorer {

    /// @notice Returns key details about the current block.
    /// @return blockNumber The current block number.
    /// @return blockTimestamp The timestamp of the current block.
    /// @return blockDifficulty The difficulty of the current block.
    /// @return coinbase The address of the miner (coinbase) for the current block.
    /// @return gasLimit The gas limit of the current block.
    function getBlockInfo() external view returns (
        uint256 blockNumber,
        uint256 blockTimestamp,
        uint256 blockDifficulty,
        address coinbase,
        uint256 gasLimit
    ) {
        blockNumber = block.number;
        blockTimestamp = block.timestamp;
        blockDifficulty = block.difficulty;
        coinbase = block.coinbase;
        gasLimit = block.gaslimit;
    }
    
    /// @notice Returns the block hash for a given block number.
    /// @param _blockNumber The block number to get the hash for. Must be within the last 256 blocks.
    /// @return blockHash The block hash.
    function getBlockHash(uint256 _blockNumber) external view returns (bytes32 blockHash) {
        require(block.number - _blockNumber < 256, "Block hash not available for blocks older than 256 blocks");
        blockHash = blockhash(_blockNumber);
    }
}
