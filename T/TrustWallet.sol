// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Limited {
    function approve(address, uint256) external returns (bool);
}

/// 💂 Secure vault requiring trusted signer + low approval cap
contract SafeVault {
    address public admin;
    mapping(address => bool) public whitelist;

    constructor() {
        admin = msg.sender;
    }

    function addTrusted(address user) external {
        require(msg.sender == admin, "Not admin");
        whitelist[user] = true;
    }

    function safeApprove(address token, address spender, uint256 amount) external {
        require(whitelist[msg.sender], "Not trusted");
        require(amount <= 1000 ether, "Cap exceeded");
        IERC20Limited(token).approve(spender, amount);
    }
}
