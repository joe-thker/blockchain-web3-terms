// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FibonacciRetracementCustom {
    /**
     * @notice Calculates Fibonacci retracement levels for a given high, low, and custom percentages.
     * @param high The high price.
     * @param low The low price.
     * @param customPercentages An array of retracement percentages in basis points (per 1000).
     * @return levels An array of retracement levels corresponding to the custom percentages.
     *
     * Each level is computed as:
     *    level = high - ((high - low) * percentage) / 1000
     */
    function calculateLevels(uint256 high, uint256 low, uint256[] calldata customPercentages) external pure returns (uint256[] memory levels) {
        require(high >= low, "High must be >= low");
        uint256 diff = high - low;
        levels = new uint256[](customPercentages.length);
        for (uint256 i = 0; i < customPercentages.length; i++) {
            levels[i] = high - ((diff * customPercentages[i]) / 1000);
        }
        return levels;
    }
}
