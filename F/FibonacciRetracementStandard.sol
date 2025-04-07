// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FibonacciRetracementStandard {
    // Standard retracement percentages in basis points (per 1000):
    // 0% = 0, 23.6% = 236, 38.2% = 382, 50% = 500, 61.8% = 618, 78.6% = 786, 100% = 1000.
    uint256[] private percentages = [0, 236, 382, 500, 618, 786, 1000];

    /**
     * @notice Calculates Fibonacci retracement levels for a given high and low price.
     * @param high The high price.
     * @param low The low price.
     * @return levels An array of retracement levels corresponding to the predefined percentages.
     *
     * For each percentage, the level is computed as:
     *    level = high - ((high - low) * percentage) / 1000
     */
    function calculateLevels(uint256 high, uint256 low) external view returns (uint256[] memory levels) {
        require(high >= low, "High must be >= low");
        uint256 diff = high - low;
        levels = new uint256[](percentages.length);
        for (uint256 i = 0; i < percentages.length; i++) {
            levels[i] = high - ((diff * percentages[i]) / 1000);
        }
        return levels;
    }
}
