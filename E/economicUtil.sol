// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title EconomicUtility
/// @notice This contract allows users to deposit an ERC20 token and calculates an "economic utility" score 
/// for each user as (deposit balance * multiplier). The multiplier is dynamic and can be updated by the owner.
/// Users can deposit and withdraw tokens at any time.
contract EconomicUtility is Ownable, ReentrancyGuard {
    // The ERC20 token that users deposit.
    IERC20 public depositToken;

    // The multiplier used to calculate the utility score.
    uint256 public multiplier;

    // Mapping to track each user's deposited token amount.
    mapping(address => uint256) public deposits;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event MultiplierUpdated(uint256 newMultiplier);

    /// @notice Constructor sets the deposit token and initial multiplier.
    /// @param _depositToken The ERC20 token address to be used for deposits.
    /// @param initialMultiplier The initial multiplier for utility calculation.
    constructor(address _depositToken, uint256 initialMultiplier) Ownable(msg.sender) {
        require(_depositToken != address(0), "Invalid token address");
        require(initialMultiplier > 0, "Multiplier must be > 0");

        depositToken = IERC20(_depositToken);
        multiplier = initialMultiplier;
    }

    /// @notice Allows users to deposit tokens into the contract.
    /// The deposited tokens will contribute to the user's economic utility.
    /// @param amount The number of tokens to deposit.
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be > 0");
        require(depositToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        deposits[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    /// @notice Allows users to withdraw tokens from the contract.
    /// Their economic utility will be updated accordingly.
    /// @param amount The number of tokens to withdraw.
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdraw amount must be > 0");
        require(deposits[msg.sender] >= amount, "Insufficient deposited balance");

        deposits[msg.sender] -= amount;
        require(depositToken.transfer(msg.sender, amount), "Token transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Returns the current economic utility score for a user.
    /// @param user The address of the user.
    /// @return The utility score, calculated as deposits[user] * multiplier.
    function utilityOf(address user) external view returns (uint256) {
        return deposits[user] * multiplier;
    }

    /// @notice Updates the multiplier used in utility calculation.
    /// This affects all users' calculated utility scores.
    /// @param newMultiplier The new multiplier value.
    function updateMultiplier(uint256 newMultiplier) external onlyOwner {
        require(newMultiplier > 0, "Multiplier must be > 0");
        multiplier = newMultiplier;
        emit MultiplierUpdated(newMultiplier);
    }
}
