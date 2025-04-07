// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FibonacciRetracementMultiple {
    // Standard retracement percentages in basis points (per 1000).
    // 0% = 0, 23.6% = 236, 38.2% = 382, 50% = 500, 61.8% = 618, 78.6% = 786, 100% = 1000.
    uint256[] private percentages = [0, 236, 382, 500, 618, 786, 1000];

    /**
     * @notice Calculates Fibonacci retracement levels for multiple high/low pairs.
     * @param highs An array of high prices.
     * @param lows An array of low prices.
     * @return levels A two-dimensional array where each inner array contains the retracement levels
     * corresponding to the high/low pair at that index.
     *
     * For each high/low pair, each level is computed as:
     *      level = high - ((high - low) * percentage) / 1000
     */
    function calculateMultipleLevels(
        uint256[] calldata highs,
        uint256[] calldata lows
    ) external view returns (uint256[][] memory levels) {
        require(highs.length == lows.length, "Arrays must be of equal length");
        levels = new uint256[][](highs.length);
        for (uint256 j = 0; j < highs.length; j++) {
            require(highs[j] >= lows[j], "High must be >= low for each pair");
            uint256 diff = highs[j] - lows[j];
            uint256[] memory levelForPair = new uint256[](percentages.length);
            for (uint256 i = 0; i < percentages.length; i++) {
                levelForPair[i] = highs[j] - ((diff * percentages[i]) / 1000);
            }
            levels[j] = levelForPair;
        }
        return levels;
    }
}
