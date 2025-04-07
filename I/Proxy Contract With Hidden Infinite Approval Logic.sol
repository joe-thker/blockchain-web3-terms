// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProxyApprover {
    address public target;

    constructor(address _target) {
        target = _target;
    }

    function approveOnBehalf(address token, address spender) external {
        // Dangerous if proxy leads to malicious logic
        IERC20(token).approve(spender, type(uint256).max);
    }
}
