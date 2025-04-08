// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title InterestRateModel
/// @notice A general-purpose contract to calculate interest in DeFi systems
contract InterestRateModel {
    
    /// @notice Calculate fixed interest (simple formula)
    /// @param principal Initial amount
    /// @param annualRate Rate in basis points (1% = 100)
    /// @param daysElapsed Duration in days
    /// @return interest Amount of interest earned
    function calculateFixedInterest(
        uint256 principal,
        uint256 annualRate,
        uint256 daysElapsed
    ) external pure returns (uint256 interest) {
        interest = (principal * annualRate * daysElapsed) / (10000 * 365);
    }

    /// @notice Calculate utilization rate (borrowed / supplied)
    /// @param totalSupplied Total pool liquidity
    /// @param totalBorrowed Total borrowed assets
    /// @return utilization Scaled to 1e18 (e.g., 0.75e18 = 75%)
    function getUtilizationRate(
        uint256 totalSupplied,
        uint256 totalBorrowed
    ) public pure returns (uint256 utilization) {
        if (totalSupplied == 0) return 0;
        utilization = (totalBorrowed * 1e18) / totalSupplied;
    }

    /// @notice Calculate variable interest rate based on utilization
    /// @param utilization Utilization rate (scaled to 1e18)
    /// @return rate Annual rate (e.g., 5% = 0.05e18)
    function getVariableRate(uint256 utilization) public pure returns (uint256 rate) {
        uint256 base = 2e16; // 2%
        uint256 slope = 18e16; // up to 20% at full usage
        rate = base + (utilization * slope) / 1e18;
    }

    /// @notice Compound interest calculation
    /// @param principal Initial value
    /// @param ratePerPeriod Interest rate per compounding period (scaled to 1e18)
    /// @param periods Number of compounding periods
    /// @return amount Final amount after interest
    function calculateCompoundInterest(
        uint256 principal,
        uint256 ratePerPeriod,
        uint256 periods
    ) external pure returns (uint256 amount) {
        amount = principal;
        for (uint256 i = 0; i < periods; i++) {
            amount += (amount * ratePerPeriod) / 1e18;
        }
    }
}
