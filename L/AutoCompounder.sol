// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title AutoCompounder
/// @notice Simulates auto-compounding rewards for a single staking token
contract AutoCompounder {
    IERC20 public reward;
    mapping(address => uint256) public balance;

    constructor(address _reward) {
        reward = IERC20(_reward);
    }

    /// @notice Deposit tokens into compounder
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        reward.transferFrom(msg.sender, address(this), amount);
        balance[msg.sender] += amount;
    }

    /// @notice Compound 10% of current balance (mock example)
    function compound(address user) external {
        uint256 earned = balance[user] / 10; // 10% growth simulation
        balance[user] += earned;
    }

    /// @notice Withdraw tokens from compounder
    function withdraw(uint256 amount) external {
        require(balance[msg.sender] >= amount, "Insufficient balance");
        balance[msg.sender] -= amount;
        reward.transfer(msg.sender, amount);
    }
}
