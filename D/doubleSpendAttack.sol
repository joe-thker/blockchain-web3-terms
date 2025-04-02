// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DoubleSpendAttackMitigator
/// @notice A dynamic and optimized contract demonstrating how to mitigate double spend attacks using a nonce-based approach.
/// Each “spend” must include a unique nonce, preventing reuse of the same nonce and thus preventing double spend attempts.
contract DoubleSpendAttackMitigator is Ownable, ReentrancyGuard {
    /// @notice Mapping from a user address => nonce => a boolean indicating if nonce is already used.
    mapping(address => mapping(uint256 => bool)) public usedNonces;

    // Optional: track user balances or something that can be “spent.”
    mapping(address => uint256) public balances;

    // --- Events ---
    event Deposit(address indexed user, uint256 amount);
    event Spent(address indexed user, uint256 amount, uint256 nonce);
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Constructor sets the deployer as the contract owner (if you wish to add admin logic).
    constructor() Ownable(msg.sender) {}

    /// @notice Users deposit Ether into the contract, which increments their balance in the mapping.
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Must deposit more than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice A user “spends” an amount from their balance. Must include a unique nonce to prevent double spend.
    /// Once a nonce is used by that user, it cannot be reused again.
    /// @param amount The amount of the user’s balance they want to spend.
    /// @param nonce A unique nonce for this spend operation.
    function spend(uint256 amount, uint256 nonce) external nonReentrant {
        require(amount > 0, "Spend amount must be > 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(!usedNonces[msg.sender][nonce], "Nonce already used");

        // Mark the nonce as used
        usedNonces[msg.sender][nonce] = true;
        // Deduct from user’s on-chain balance
        balances[msg.sender] -= amount;

        // In a real scenario, this “spent” amount might be sent to a different contract 
        // or used for some logic. For demonstration, we do nothing else with it.

        emit Spent(msg.sender, amount, nonce);
    }

    /// @notice Users can withdraw their remaining Ether balance. Nonce not required for withdrawal, 
    /// as we only track “spends” that can’t be repeated.
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");

        // Reset the user’s balance
        balances[msg.sender] = 0;

        // Transfer Ether to the user
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Returns the current on-chain balance for a user.
    /// @param user The user address.
    /// @return The user’s balance.
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
