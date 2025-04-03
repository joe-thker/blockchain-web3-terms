// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DYCO (Dynamic Coin Offering)
/// @notice This contract implements a dynamic coin offering for an ERC20 token.
/// During the offering period, users can buy tokens by sending Ether. The token price is dynamic,
/// increasing linearly from a base rate at the start time to double the base rate at the end time.
/// The owner can withdraw the raised funds at any time.
contract DYCO is ERC20, Ownable, ReentrancyGuard {
    // Offering parameters
    uint256 public startTime;
    uint256 public endTime;
    uint256 public baseRate; // Number of tokens per wei at start
    uint256 public totalRaised; // Total Ether raised (in wei)

    /// @notice Constructor sets the token name, symbol, and offering parameters.
    /// @param _startTime The Unix timestamp when the offering begins.
    /// @param _endTime The Unix timestamp when the offering ends.
    /// @param _baseRate The base rate (tokens per wei) at the start of the offering.
    constructor(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _baseRate
    )
        ERC20("DYCO Token", "DYCO")
        Ownable(msg.sender)
    {
        require(_startTime < _endTime, "Start time must be before end time");
        require(_baseRate > 0, "Base rate must be > 0");
        startTime = _startTime;
        endTime = _endTime;
        baseRate = _baseRate;
    }

    /// @notice Calculates the current token rate (tokens per wei) dynamically based on the current time.
    /// - Before the offering starts: returns baseRate.
    /// - After the offering ends: returns baseRate * 2.
    /// - During the offering: linearly interpolates between baseRate and baseRate * 2.
    /// @return The current token rate (tokens per wei).
    function currentRate() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return baseRate;
        } else if (block.timestamp > endTime) {
            return baseRate * 2;
        } else {
            uint256 elapsed = block.timestamp - startTime;
            uint256 duration = endTime - startTime;
            uint256 rateIncrease = (baseRate * elapsed) / duration; // increases from 0 to baseRate
            return baseRate + rateIncrease;
        }
    }

    /// @notice Allows users to buy tokens during the offering period by sending Ether.
    /// Tokens are minted at the current dynamic rate.
    function buyTokens() external payable nonReentrant {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Offering not active");
        require(msg.value > 0, "Must send Ether to buy tokens");

        uint256 rate = currentRate();
        uint256 tokensToMint = msg.value * rate;
        totalRaised += msg.value;
        _mint(msg.sender, tokensToMint);
    }

    /// @notice Allows the owner to withdraw the Ether raised during the offering.
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: contractBalance}("");
        require(success, "Withdrawal failed");
    }
}
