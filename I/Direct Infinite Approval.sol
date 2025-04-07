// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InfiniteApprovalDirect {
    function approveMax(address token, address spender) external {
        IERC20(token).approve(spender, type(uint256).max);
    }
}
