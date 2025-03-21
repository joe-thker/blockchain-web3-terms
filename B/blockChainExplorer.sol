// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockchainExplorer
/// @notice A simple contract that provides basic blockchain data, such as block details and block hashes.
contract BlockchainExplorer {
    
    /// @notice Returns key details about the current block.
    /// @return blockNumber The current block number.
    /// @return blockTimestamp The timestamp of the current block.
    /// @return blockDifficulty The difficulty of the current block.
    /// @return coinbase The address of the miner (coinbase) for the current block.
    /// @return gasLimit The gas limit of the current block.
    function getBlockDetails() external view returns (
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
    /// @param _blockNumber The block number for which to get the hash.
    /// @return blockHash The block hash.
    function getBlockHash(uint256 _blockNumber) external view returns (bytes32 blockHash) {
        // Blockhash is available only for the 256 most recent blocks.
        require(block.number > _blockNumber && block.number - _blockNumber < 256, "Block hash not available");
        blockHash = blockhash(_blockNumber);
    }
}
