// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockHeight
/// @notice A simple contract that returns the current block height.
contract BlockHeight {
    /// @notice Returns the current block height (i.e., the block number).
    /// @return The current block number, which is equivalent to the block height.
    function getBlockHeight() public view returns (uint256) {
        return block.number;
    }
}
