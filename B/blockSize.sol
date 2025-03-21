// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockSizeInfo
/// @notice This contract returns the current block's gas limit, which serves as an approximation for block size in Ethereum.
contract BlockSizeInfo {
    /// @notice Retrieves the block's gas limit.
    /// @return gasLimit The gas limit of the current block.
    function getBlockSize() public view returns (uint256 gasLimit) {
        gasLimit = block.gaslimit;
    }
}
