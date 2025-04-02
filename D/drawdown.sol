// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Drawdown
/// @notice A dynamic, optimized contract allowing users to deposit an ERC20 token into a locked balance,
/// then partially withdraw ("draw down") increments of their balance. The owner can optionally apply further rules.
contract Drawdown is Ownable, ReentrancyGuard {
    /// @notice The ERC20 token used for deposits/withdrawals (e.g., stablecoin).
    IERC20 public token;

    /// @notice Mapping from user address => locked token balance.
    mapping(address => uint256) public lockedBalance;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount);
    event DrawnDown(address indexed user, uint256 drawAmount);
    event FullyWithdrawn(address indexed user, uint256 remainingBalance);

    /// @notice Constructor sets the ERC20 token address used for deposits.
    /// The contract is owned by the deployer (via Ownable(msg.sender)) if you need admin actions later.
    /// @param _token The address of the ERC20 token (e.g., a stablecoin).
    constructor(address _token) Ownable(msg.sender) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    /// @notice Users deposit tokens into a locked balance. They must have approved this contract for `amount`.
    /// @param amount The quantity of tokens (in smallest units) to deposit.
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be > 0");
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        lockedBalance[msg.sender] += amount;

        emit Deposited(msg.sender, amount);
    }

    /// @notice Users draw down (partially withdraw) a portion of their locked balance.
    /// This draws from their lockedBalance, transferring tokens back to them.
    /// @param drawAmount The amount of tokens to withdraw (must be <= locked balance).
    function drawDown(uint256 drawAmount) external nonReentrant {
        require(drawAmount > 0, "Draw amount must be > 0");
        uint256 bal = lockedBalance[msg.sender];
        require(bal >= drawAmount, "Insufficient locked balance");

        lockedBalance[msg.sender] = bal - drawAmount;

        bool success = token.transfer(msg.sender, drawAmount);
        require(success, "Token transfer failed");

        emit DrawnDown(msg.sender, drawAmount);
    }

    /// @notice Users can fully withdraw (drawdown) their entire remaining balance in one call.
    /// This might be a convenience function for a final exit.
    function fullyWithdraw() external nonReentrant {
        uint256 bal = lockedBalance[msg.sender];
        require(bal > 0, "No locked balance to withdraw");
        lockedBalance[msg.sender] = 0;

        bool success = token.transfer(msg.sender, bal);
        require(success, "Token transfer failed");

        emit FullyWithdrawn(msg.sender, bal);
    }

    // --- Optional Admin/Owner Functions for Extended Logic ---

    /// @notice Owner can forcibly reduce a user’s balance (a slash or penalty), for instance. 
    /// This function is optional and an example if you want admin oversight. 
    /// @param user The user whose lockedBalance is reduced.
    /// @param amount The amount to reduce from user’s lockedBalance.
    function adminReduceBalance(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(lockedBalance[user] >= amount, "Insufficient user balance");

        lockedBalance[user] -= amount;
        // The removed tokens remain in the contract. 
        // In real usage, you might want to burn them or store them as “slashed” – up to your logic.
    }

    /// @notice Returns the user’s locked balance for external calls.
    /// @param user The address to check.
    /// @return The locked token balance of that user.
    function getLockedBalance(address user) external view returns (uint256) {
        return lockedBalance[user];
    }
}
