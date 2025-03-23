// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StandardBayesCalculator {
    uint256 public constant SCALE = 1e18; // Scale factor for fixed-point arithmetic

    /// @notice Calculates P(A|B) = (P(B|A) * P(A)) / P(B)
    /// @param pBgivenA Probability P(B|A), scaled by 1e18
    /// @param pA Probability P(A), scaled by 1e18
    /// @param pB Probability P(B), scaled by 1e18
    /// @return pAgivenB The posterior probability P(A|B), scaled by 1e18
    function calculateBayes(
        uint256 pBgivenA,
        uint256 pA,
        uint256 pB
    ) public pure returns (uint256 pAgivenB) {
        require(pB > 0, "P(B) must be > 0");
        pAgivenB = (pBgivenA * pA) / pB;
    }
}
