// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ApprovalRegistry {
    mapping(address => mapping(address => uint256)) public approvedAmounts;

    function approve(address token, address spender, uint256 amount) external {
        require(amount < type(uint256).max, "Infinite approval not allowed");
        IERC20(token).approve(spender, amount);
        approvedAmounts[msg.sender][spender] = amount;
    }

    function revoke(address token, address spender) external {
        IERC20(token).approve(spender, 0);
        approvedAmounts[msg.sender][spender] = 0;
    }
}
