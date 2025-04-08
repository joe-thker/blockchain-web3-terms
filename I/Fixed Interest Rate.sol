// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FixedInterestCalculator
/// @notice Calculates simple interest on a principal amount
contract FixedInterestCalculator {

    /// @notice Calculate fixed interest over a number of days
    /// @param principal Amount being lent or deposited
    /// @param rate Interest rate in basis points (1% = 100)
    /// @param timeInDays Duration in days
    /// @return interest Total interest accrued
    function calculateFixedInterest(
        uint256 principal,
        uint256 rate,
        uint256 timeInDays
    ) public pure returns (uint256 interest) {
        // Formula: Interest = Principal * Rate * Time / (100 * 365)
        interest = (principal * rate * timeInDays) / (10000 * 365);
    }
}
