// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title InfiniteApprovalRegistry
/// @notice Tracks and allows revocation of infinite approvals to prevent token drain risks
contract InfiniteApprovalRegistry {
    // Mapping: user => spender => is infinite approval active
    mapping(address => mapping(address => bool)) public isInfiniteApproved;

    /// @notice Call this after doing an approval to track if it was infinite
    function trackApproval(address token, address spender, uint256 amount) external {
        if (amount == type(uint256).max) {
            isInfiniteApproved[msg.sender][spender] = true;
        }
    }

    /// @notice Revoke approval to the spender if you previously approved max
    function revoke(address token, address spender) external {
        IERC20(token).approve(spender, 0); // Revoke approval
        isInfiniteApproved[msg.sender][spender] = false;
    }
}
