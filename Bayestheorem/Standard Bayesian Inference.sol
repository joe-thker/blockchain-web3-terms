// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BayesCalculator
/// @notice A contract to calculate Bayes' Theorem using fixed-point arithmetic.
/// @dev All probabilities are assumed to be scaled by 1e18 (i.e., 100% = 1e18).
contract BayesCalculator {
    uint256 public constant SCALE = 1e18;

    /// @notice Calculates the posterior probability P(A|B) using Bayes' Theorem.
    /// @param pBgivenA The probability P(B|A), scaled by 1e18.
    /// @param pA The prior probability P(A), scaled by 1e18.
    /// @param pB The probability P(B), scaled by 1e18.
    /// @return pAgivenB The posterior probability P(A|B), scaled by 1e18.
    function calculateBayes(
        uint256 pBgivenA,
        uint256 pA,
        uint256 pB
    ) public pure returns (uint256 pAgivenB) {
        require(pB > 0, "P(B) must be > 0");
        // Calculation:
        // P(A|B) = (P(B|A) * P(A)) / P(B)
        // Since all values are scaled by 1e18, the multiplication gives a scale of 1e36.
        // Dividing by pB (scaled 1e18) brings the result back to 1e18 scale.
        pAgivenB = (pBgivenA * pA) / pB;
    }
}
