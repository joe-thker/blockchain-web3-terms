// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NaiveBayesClassifier {
    uint256 public constant SCALE = 1e18;

    /// @notice Classifies based on two features using Naïve Bayes.
    /// @param pC Prior probability of class C, scaled by 1e18.
    /// @param pF1givenC Likelihood of feature 1 given C, scaled by 1e18.
    /// @param pF2givenC Likelihood of feature 2 given C, scaled by 1e18.
    /// @param pF1 Marginal probability of feature 1, scaled by 1e18.
    /// @param pF2 Marginal probability of feature 2, scaled by 1e18.
    /// @return posterior The computed posterior probability for class C, scaled by 1e18.
    function classify(
        uint256 pC,
        uint256 pF1givenC,
        uint256 pF2givenC,
        uint256 pF1,
        uint256 pF2
    ) public pure returns (uint256 posterior) {
        require(pF1 > 0 && pF2 > 0, "Marginal probabilities must be > 0");
        // Compute numerator: pC * pF1givenC * pF2givenC
        uint256 numerator = (pC * pF1givenC) / SCALE;
        numerator = (numerator * pF2givenC) / SCALE;
        // For a simple classifier, we divide by the product of marginal probabilities.
        uint256 denominator = (pF1 * pF2) / SCALE;
        posterior = (numerator * SCALE) / denominator;
    }
}
