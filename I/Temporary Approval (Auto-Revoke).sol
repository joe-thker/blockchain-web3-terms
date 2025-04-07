// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TemporaryApproval {
    function temporaryApprove(address token, address spender, uint256 amount) external {
        IERC20(token).approve(spender, amount);
        
        // Placeholder: logic using token (like swap)

        IERC20(token).approve(spender, 0); // Immediately revoke
    }
}
