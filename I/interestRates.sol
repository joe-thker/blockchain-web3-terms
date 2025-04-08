// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiInterestRateModel {
    // 1% = 100 (basis points), 1e18 = fixed-point for decimals

    /// @notice Calculate fixed interest
    function fixedRate(
        uint256 principal,
        uint256 bpsRate,
        uint256 daysElapsed
    ) public pure returns (uint256) {
        return (principal * bpsRate * daysElapsed) / (10000 * 365);
    }

    /// @notice Calculate utilization = borrowed / supplied
    function utilizationRate(
        uint256 supplied,
        uint256 borrowed
    ) public pure returns (uint256) {
        if (supplied == 0) return 0;
        return (borrowed * 1e18) / supplied;
    }

    /// @notice Dynamic variable rate = base + slope * utilization
    function variableRate(uint256 utilization) public pure returns (uint256) {
        uint256 base = 2e16;  // 2%
        uint256 slope = 18e16; // scale up to 20%
        return base + (utilization * slope) / 1e18;
    }

    /// @notice Compound interest calculator
    function compoundRate(
        uint256 principal,
        uint256 ratePerPeriod,
        uint256 periods
    ) public pure returns (uint256) {
        uint256 amount = principal;
        for (uint256 i = 0; i < periods; i++) {
            amount += (amount * ratePerPeriod) / 1e18;
        }
        return amount;
    }

    /// @notice Duration-based rate adjustment
    function durationAdjustedRate(uint256 baseRate, uint256 daysLocked) public pure returns (uint256) {
        uint256 bonus = (daysLocked * 1e16) / 365; // +1% per year locked
        return baseRate + bonus;
    }

    /// @notice Risk-tiered rate (e.g. higher rate for lower risk)
    function riskWeightedRate(uint256 baseRate, uint8 riskTier) public pure returns (uint256) {
        require(riskTier >= 1 && riskTier <= 5, "Tier out of range");
        uint256 discount = (5 - riskTier) * 5e15; // reduce 0.5% per lower tier
        return baseRate - discount;
    }
}
