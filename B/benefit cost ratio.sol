// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BenefitCostRatioCalculator
/// @notice A contract to calculate the Benefit-Cost Ratio (BCR) for a project or decision.
/// @dev The BCR is calculated as (benefit / cost), scaled by 1e18 to handle decimals.
contract BenefitCostRatioCalculator {
    // Scale factor for fixed-point arithmetic
    uint256 public constant SCALE = 1e18;

    // Event emitted when the ratio is calculated
    event RatioCalculated(uint256 benefit, uint256 cost, uint256 ratio);

    /// @notice Calculates the Benefit-Cost Ratio (BCR) given benefit and cost.
    /// @param benefit The total benefit (should be scaled accordingly).
    /// @param cost The total cost (must be > 0, and scaled accordingly).
    /// @return ratio The calculated benefit-cost ratio, scaled by 1e18.
    function calculateBCR(uint256 benefit, uint256 cost) public pure returns (uint256 ratio) {
        require(cost > 0, "Cost must be greater than 0");
        // Calculate ratio: (benefit / cost) scaled by 1e18
        ratio = (benefit * SCALE) / cost;
    }

    /// @notice Calculates the BCR and emits an event with the result.
    /// @param benefit The total benefit.
    /// @param cost The total cost.
    function calculateAndEmit(uint256 benefit, uint256 cost) public {
        uint256 ratio = calculateBCR(benefit, cost);
        emit RatioCalculated(benefit, cost, ratio);
    }
}
