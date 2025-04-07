// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ApprovalWithTimeout {
    mapping(address => mapping(address => uint256)) public approvalExpires;

    function approveWithTimeout(
        address token,
        address spender,
        uint256 amount,
        uint256 timeout
    ) external {
        IERC20(token).approve(spender, amount);
        approvalExpires[msg.sender][spender] = block.timestamp + timeout;
    }

    function revokeIfExpired(address token, address spender) external {
        require(block.timestamp >= approvalExpires[msg.sender][spender], "Approval still active");
        IERC20(token).approve(spender, 0);
        approvalExpires[msg.sender][spender] = 0;
    }
}
