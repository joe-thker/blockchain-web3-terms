// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simple Hosted Wallet System
contract HostedWallet {
    address public host;

    mapping(address => uint256) private balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event HostTransfer(address indexed from, address indexed to, uint256 amount);

    modifier onlyHost() {
        require(msg.sender == host, "Only host can perform this action");
        _;
    }

    constructor() {
        host = msg.sender;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw by user (optional, or restricted)
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Host transfers funds on behalf of user
    function hostTransfer(address from, address to, uint256 amount) external onlyHost {
        require(balances[from] >= amount, "Insufficient user balance");
        balances[from] -= amount;
        balances[to] += amount;
        emit HostTransfer(from, to, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
