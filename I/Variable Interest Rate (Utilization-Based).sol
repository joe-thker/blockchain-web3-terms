// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VariableInterestRateModel
/// @notice Dynamic interest rate model based on pool utilization
contract VariableInterestRateModel {
    
    /// @notice Calculates the utilization rate of the lending pool
    /// @param totalSupplied Total assets supplied to the pool
    /// @param totalBorrowed Total assets borrowed from the pool
    /// @return utilization Utilization rate scaled to 1e18 (e.g., 75% = 0.75e18)
    function getUtilizationRate(uint256 totalSupplied, uint256 totalBorrowed) public pure returns (uint256 utilization) {
        if (totalSupplied == 0) return 0;
        utilization = (totalBorrowed * 1e18) / totalSupplied;
    }

    /// @notice Calculates the dynamic interest rate based on utilization
    /// @param utilization Utilization rate scaled to 1e18
    /// @return interestRate Annual interest rate scaled to 1e18 (e.g., 5% = 0.05e18)
    function getDynamicInterestRate(uint256 utilization) public pure returns (uint256 interestRate) {
        // Base rate = 2%, scale up linearly to 20% max
        uint256 baseRate = 2e16;        // 2%
        uint256 slope = 18e16;          // additional 18% at 100% utilization
        interestRate = baseRate + (utilization * slope) / 1e18;
    }
}
