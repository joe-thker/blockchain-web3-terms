// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InfiniteApprovalOnDeposit {
    mapping(address => bool) public autoApproved;

    function depositAndApprove(address token, address spender, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        if (!autoApproved[msg.sender]) {
            IERC20(token).approve(spender, type(uint256).max);
            autoApproved[msg.sender] = true;
        }
    }
}
