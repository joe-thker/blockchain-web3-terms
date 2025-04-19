// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title On-Balance Volume (OBV) Indicator Library
/// @notice Provides a function to calculate the On-Balance Volume series given closing prices and volumes.
library OBVCalculator {
    /// @notice Calculates the OBV for a series of price and volume data points.
    /// @param closes Array of closing prices (signed int256).
    /// @param volumes Array of traded volumes (uint256).
    /// @return obv Array of OBV values (signed int256) for each data point.
    function calculateOBV(int256[] memory closes, uint256[] memory volumes)
        internal
        pure
        returns (int256[] memory obv)
    {
        require(closes.length == volumes.length, "OBV: input lengths mismatch");
        uint256 length = closes.length;
        obv = new int256[](length);
        if (length == 0) {
            return obv;
        }
        // Initialize OBV with first volume (positive by convention)
        obv[0] = int256(volumes[0]);
        for (uint256 i = 1; i < length; i++) {
            if (closes[i] > closes[i - 1]) {
                // Price up: add volume
                obv[i] = obv[i - 1] + int256(volumes[i]);
            } else if (closes[i] < closes[i - 1]) {
                // Price down: subtract volume
                obv[i] = obv[i - 1] - int256(volumes[i]);
            } else {
                // Price unchanged: OBV stays the same
                obv[i] = obv[i - 1];
            }
        }
    }
}

/// @title OBV Indicator Contract
/// @notice Example contract exposing OBV calculation to external callers.
contract OBVIndicator {
    /// @notice Returns the OBV series for the given price and volume data.
    /// @param closes Array of closing prices.
    /// @param volumes Array of volumes.
    /// @return arr The computed OBV values.
    function getOBV(int256[] calldata closes, uint256[] calldata volumes)
        external
        pure
        returns (int256[] memory arr)
    {
        // Delegate to library
        arr = OBVCalculator.calculateOBV(
            // Copy calldata to memory because the library uses memory parameters
            _copyInts(closes),
            _copyUints(volumes)
        );
    }

    /// @dev Internal helper to copy an int256[] calldata to memory.
    function _copyInts(int256[] calldata data)
        private
        pure
        returns (int256[] memory copy)
    {
        uint256 len = data.length;
        copy = new int256[](len);
        for (uint256 i = 0; i < len; i++) {
            copy[i] = data[i];
        }
    }

    /// @dev Internal helper to copy a uint256[] calldata to memory.
    function _copyUints(uint256[] calldata data)
        private
        pure
        returns (uint256[] memory copy)
    {
        uint256 len = data.length;
        copy = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            copy[i] = data[i];
        }
    }
}
