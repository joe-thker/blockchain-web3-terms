// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ApprovalLimiter {
    uint256 public constant MAX_APPROVAL = 1000 * 1e18;

    function safeApprove(address token, address spender, uint256 amount) external {
        require(amount <= MAX_APPROVAL, "Exceeds safe approval limit");
        IERC20(token).approve(spender, amount);
    }
}
