// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title OFACCompliantVault - Blocks access from sanctioned (OFAC-listed) addresses
contract OFACCompliantVault {
    address public admin;
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Blacklisted(address indexed user, bool status);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier notBlacklisted() {
        require(!isBlacklisted[msg.sender], "OFAC-restricted address");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setBlacklist(address user, bool status) external onlyAdmin {
        isBlacklisted[user] = status;
        emit Blacklisted(user, status);
    }

    function deposit() external payable notBlacklisted {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notBlacklisted {
        require(balances[msg.sender] >= amount, "Insufficient");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    receive() external payable {
        deposit();
    }
}
