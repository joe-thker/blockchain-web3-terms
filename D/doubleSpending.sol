// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DoubleSpending
/// @notice Demonstrates a dynamic, optimized contract that prevents double spending of on-chain balances
/// by requiring each spend call to provide a unique nonce that cannot be reused.
contract DoubleSpending is ReentrancyGuard {
    /// @notice Mapping from user => their on-chain Ether balance (in wei).
    mapping(address => uint256) public balances;

    /// @notice Mapping from user => (nonce => bool) indicating whether a nonce has been used for spending.
    mapping(address => mapping(uint256 => bool)) public usedNonces;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount);
    event Spent(address indexed user, uint256 amount, uint256 nonce);
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Users deposit Ether into this contract. The deposit function is external and nonReentrant.
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Must deposit > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice A user "spends" an amount of their on-chain balance, requiring a unique nonce to prevent double spending.
    /// @param amount The amount to spend.
    /// @param nonce A user-chosen, unique nonce for this spend operation.
    function spend(uint256 amount, uint256 nonce) external nonReentrant {
        require(amount > 0, "Spend amount must be > 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(!usedNonces[msg.sender][nonce], "Nonce already used (double spend attempt?)");

        // Mark this nonce as used
        usedNonces[msg.sender][nonce] = true;

        // Deduct the amount from the user's on-chain balance
        balances[msg.sender] -= amount;

        // The "spent" Ether is effectively consumed. In a real scenario, you might forward it to a merchant
        // or burn it, etc. For demonstration, we simply remove it from the user's balance.

        emit Spent(msg.sender, amount, nonce);
    }

    /// @notice Allows a user to withdraw their remaining Ether from the contract, using a pull-payment approach.
    /// There's no nonce required for withdrawal since the contract no longer holds that portion once withdrawn.
    function withdraw() external nonReentrant {
        uint256 userBal = balances[msg.sender];
        require(userBal > 0, "No funds to withdraw");
        balances[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: userBal}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, userBal);
    }

    /// @notice Returns the user’s current on-chain balance in this contract.
    /// @param user The user address.
    /// @return The balance in wei.
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
