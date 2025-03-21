// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockTime
/// @notice A contract that provides information about block time metrics.
contract BlockTime {
    
    /// @notice Returns the current block timestamp.
    /// @return The timestamp of the current block.
    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /// @notice Returns the current block number.
    /// @return The current block number.
    function getBlockNumber() external view returns (uint256) {
        return block.number;
    }
    
    /// @notice Returns both block timestamp and block number.
    /// @return timestamp The timestamp of the current block.
    /// @return number The current block number.
    function getBlockTimeInfo() external view returns (uint256 timestamp, uint256 number) {
        return (block.timestamp, block.number);
    }
}
