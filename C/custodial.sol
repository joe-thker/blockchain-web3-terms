// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title CustodialWallet
/// @notice A dynamic and optimized custodial wallet contract. Users deposit Ether into their balance,
/// and the owner (custodian) can grant or revoke withdrawal permission for users. Once allowed,
/// users may withdraw their funds. The owner also has an emergency withdrawal function.
contract CustodialWallet is Ownable, ReentrancyGuard {
    // Mapping from user address to deposited balance (in wei).
    mapping(address => uint256) public balances;
    // Mapping from user address to withdrawal permission.
    mapping(address => bool) public withdrawalPermission;

    // --- Events ---
    event Deposit(address indexed user, uint256 amount);
    event WithdrawalPermissionUpdated(address indexed user, bool permitted);
    event Withdraw(address indexed user, uint256 amount);
    event CustodianWithdrawal(address indexed to, uint256 amount);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // No additional initialization required.
    }

    /// @notice Deposits ETH into the sender's balance.
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Deposit must be > 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Allows the owner to set withdrawal permission for a specific user.
    /// @param user The address of the user.
    /// @param permitted True to allow withdrawal, false to revoke.
    function setWithdrawalPermission(address user, bool permitted) external onlyOwner {
        require(user != address(0), "Invalid user address");
        withdrawalPermission[user] = permitted;
        emit WithdrawalPermissionUpdated(user, permitted);
    }

    /// @notice Allows a user with withdrawal permission to withdraw their entire balance.
    function withdraw() external nonReentrant {
        require(withdrawalPermission[msg.sender], "Withdrawal not permitted");
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");

        // Set balance to zero before transferring to prevent reentrancy.
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit Withdraw(msg.sender, amount);
    }

    /// @notice Emergency function that allows the owner to withdraw all funds from the contract.
    /// @param to The address to receive the funds.
    function emergencyWithdraw(address to) external onlyOwner nonReentrant {
        require(to != address(0), "Invalid address");
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");

        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Emergency withdrawal failed");

        emit CustodianWithdrawal(to, amount);
    }

    /// @notice Fallback function to receive Ether.
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
