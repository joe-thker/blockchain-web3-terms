// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title UnbankedVault - Simple savings vault for the unbanked
contract UnbankedVault {
    mapping(address => uint256) public balances;
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Deposit ETH to vault
    function deposit() external payable {
        require(msg.value > 0, "Must deposit > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw your balance
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice View balance
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    receive() external payable {
        deposit();
    }
}
