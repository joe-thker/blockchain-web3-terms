// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BayesianNetworkExample {
    uint256 public constant SCALE = 1e18;

    /// @notice Computes P(B) given P(A), P(B|A), and P(B|not A).
    /// @param pA Probability of A, scaled by 1e18.
    /// @param pBgivenA Probability of B given A, scaled by 1e18.
    /// @param pBgivenNotA Probability of B given not A, scaled by 1e18.
    /// @return pB The probability of B, scaled by 1e18.
    function computeProbability(
        uint256 pA,
        uint256 pBgivenA,
        uint256 pBgivenNotA
    ) public pure returns (uint256 pB) {
        uint256 part1 = (pA * pBgivenA) / SCALE;
        uint256 part2 = ((SCALE - pA) * pBgivenNotA) / SCALE;
        pB = part1 + part2;
    }
}
