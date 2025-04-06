// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title HotWalletVault - On-chain ETH wallet for fast access
contract HotWalletVault {
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Deposit ETH into the hot wallet
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw ETH instantly
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice View wallet balance
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
