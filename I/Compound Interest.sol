// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CompoundInterestCalculator
/// @notice Calculates compound interest over n periods
contract CompoundInterestCalculator {
    
    /// @notice Calculates compound interest
    /// @param principal Initial deposit amount
    /// @param ratePerPeriod Interest rate per period (scaled by 1e18)
    /// @param periods Number of compounding periods
    /// @return amount Final amount after compound interest
    function calculateCompoundInterest(
        uint256 principal,
        uint256 ratePerPeriod,
        uint256 periods
    ) public pure returns (uint256 amount) {
        amount = principal;

        for (uint256 i = 0; i < periods; i++) {
            amount += (amount * ratePerPeriod) / 1e18;
        }
    }
}
