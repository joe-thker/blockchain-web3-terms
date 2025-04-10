// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Simple On-Chain Ledger
contract Ledger {
    address public admin;
    mapping(address => uint256) public balances;

    event Credited(address indexed user, uint256 amount);
    event Debited(address indexed user, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function credit(address user, uint256 amount) external onlyAdmin {
        balances[user] += amount;
        emit Credited(user, amount);
    }

    function debit(address user, uint256 amount) external onlyAdmin {
        require(balances[user] >= amount, "Insufficient balance");
        balances[user] -= amount;
        emit Debited(user, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
