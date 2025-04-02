// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DDOSAttackMitigator
/// @notice A dynamic and optimized contract demonstrating a pull-payment pattern to mitigate DoS (or DDoS) attacks.
/// Users deposit Ether, which is stored in a mapping. They later withdraw their own funds, preventing any external calls
/// that could be malicious or cause blocking issues.
contract DDOSAttackMitigator is Ownable, ReentrancyGuard {
    /// @notice Mapping from user address to their deposited Ether balance (in wei).
    mapping(address => uint256) public balances;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Constructor sets the deployer as the initial owner (if you wish to add admin logic).
    constructor() Ownable(msg.sender) {}

    /// @notice Users deposit Ether into the contract, which increments their balance in the mapping.
    /// The deposit function is external and nonReentrant to avoid reentrancy attacks.
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Must deposit more than 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw function that uses a pull approach. The user withdraws their balance themselves,
    /// preventing the contract from pushing funds to external addresses.
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");

        // Set their balance to zero before transferring out, preventing reentrancy.
        balances[msg.sender] = 0;

        // Perform a low-level call to transfer Ether. If it fails, revert.
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Fallback function to receive Ether from direct transfers.
    /// Internally calls deposit() to record the user’s balance.
    receive() external payable {
        // Optional: automatically deposit to the sender's balance.
        // We can replicate deposit logic, or keep it blank. 
        // For demonstration, we replicate deposit logic:
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}
