// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title InsuranceFund
/// @notice A basic insurance fund contract for protocol loss coverage.
contract InsuranceFund is Ownable {
    IERC20 public immutable stableToken; // e.g., USDC
    uint256 public totalReserves;

    event Deposited(address indexed user, uint256 amount);
    event EmergencyPayout(address indexed recipient, uint256 amount);
    event ToppedUp(address indexed source, uint256 amount);

    constructor(address _stableToken) Ownable(msg.sender) {
        stableToken = IERC20(_stableToken);
    }

    /// @notice Public or partner protocols can deposit to the insurance pool
    function deposit(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        stableToken.transferFrom(msg.sender, address(this), amount);
        totalReserves += amount;
        emit Deposited(msg.sender, amount);
    }

    /// @notice Protocol owner can trigger payout during emergency
    function emergencyPayout(address recipient, uint256 amount) external onlyOwner {
        require(amount <= totalReserves, "Insufficient reserves");
        totalReserves -= amount;
        stableToken.transfer(recipient, amount);
        emit EmergencyPayout(recipient, amount);
    }

    /// @notice Top up the fund manually (from treasury or strategy yield)
    function topUp(uint256 amount) external onlyOwner {
        stableToken.transferFrom(msg.sender, address(this), amount);
        totalReserves += amount;
        emit ToppedUp(msg.sender, amount);
    }

    /// @notice View fund health
    function fundBalance() external view returns (uint256) {
        return stableToken.balanceOf(address(this));
    }
}
