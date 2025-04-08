// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title InterestRateTypes
/// @notice Demonstrates different types of interest rate models in Solidity
contract InterestRateTypes {

    /// 1. Fixed Interest Rate (Simple Interest)
    function fixedInterest(uint256 principal, uint256 bpsRate, uint256 daysElapsed) external pure returns (uint256) {
        return (principal * bpsRate * daysElapsed) / (10000 * 365);
    }

    /// 2. Variable Interest Rate Based on Utilization
    function utilizationRate(uint256 totalSupplied, uint256 totalBorrowed) public pure returns (uint256) {
        if (totalSupplied == 0) return 0;
        return (totalBorrowed * 1e18) / totalSupplied;
    }

    function variableInterestRate(uint256 utilization) public pure returns (uint256) {
        uint256 baseRate = 2e16; // 2%
        uint256 slope = 18e16; // up to 20% at 100% utilization
        return baseRate + (utilization * slope) / 1e18;
    }

    /// 3. Compound Interest
    function compoundInterest(uint256 principal, uint256 ratePerPeriod, uint256 periods) public pure returns (uint256 amount) {
        amount = principal;
        for (uint256 i = 0; i < periods; i++) {
            amount += (amount * ratePerPeriod) / 1e18;
        }
    }

    /// 4. Duration-Based Rate
    function durationAdjustedRate(uint256 baseRate, uint256 lockDays) public pure returns (uint256) {
        uint256 bonus = (lockDays * 1e16) / 365; // bonus up to 1% per year locked
        return baseRate + bonus;
    }

    /// 5. Risk-Tiered Interest Rate
    function riskWeightedRate(uint256 baseRate, uint8 riskTier) public pure returns (uint256) {
        require(riskTier >= 1 && riskTier <= 5, "Invalid tier");
        uint256 discount = (5 - riskTier) * 5e15; // 0.5% discount per tier lower
        return baseRate - discount;
    }
} 
