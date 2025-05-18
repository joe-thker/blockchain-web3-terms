// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FinCENGuardedToken - ERC20-style token with sanction check
contract FinCENGuardedToken {
    address public immutable admin;
    mapping(address => bool) public sanctioned;
    mapping(address => uint256) public balance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Sanctioned(address indexed user);
    event Unsanctioned(address indexed user);

    modifier notSanctioned(address user) {
        require(!sanctioned[user], "Address sanctioned by FinCEN logic");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function transfer(address to, uint256 amount) external notSanctioned(msg.sender) notSanctioned(to) {
        require(balance[msg.sender] >= amount, "Insufficient");
        balance[msg.sender] -= amount;
        balance[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function setSanction(address user, bool status) external {
        require(msg.sender == admin, "Not admin");
        sanctioned[user] = status;
        if (status) emit Sanctioned(user);
        else emit Unsanctioned(user);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "Not admin");
        balance[to] += amount;
    }
}
