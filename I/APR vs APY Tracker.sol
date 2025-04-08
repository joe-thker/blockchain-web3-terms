// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title APR vs APY Calculator
/// @notice Converts APR to APY using compounding formula
contract APRvsAPYTracker {
    
    /// @notice Calculate APY from APR and compounding periods
    /// @param apr Annual Percentage Rate (scaled by 1e18, e.g., 10% = 1e17)
    /// @param compoundingPeriods Number of times interest compounds in a year
    /// @return apy Annual Percentage Yield (scaled by 1e18)
    function calculateAPY(uint256 apr, uint256 compoundingPeriods) public pure returns (uint256 apy) {
        require(compoundingPeriods > 0, "Must compound at least once");

        uint256 base = 1e18 + (apr / compoundingPeriods); // (1 + r/n)
        apy = base;

        for (uint256 i = 1; i < compoundingPeriods; i++) {
            apy = (apy * base) / 1e18; // compound n times
        }

        apy = apy - 1e18; // Subtract the base (1) to get only yield portion
    }
}
