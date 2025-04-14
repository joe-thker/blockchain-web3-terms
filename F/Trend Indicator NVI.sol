// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NegativeVolumeIndex_Volatility
/// @notice A simplified Negative Volume Index (NVI) that updates daily only when the
///         absolute price change percentage exceeds a specified volatility threshold.
///         Values are scaled for precision (NVI scaled by 1e18, volatility threshold scaled by 1e6).
contract NegativeVolumeIndex_Volatility {
    // NVI value (scaled by 1e18)
    int256 public nvi;
    // Last recorded price (scaled by 1e18)
    uint256 public lastPrice;
    // Last recorded volume (unit depends on context)
    uint256 public lastVolume;
    // Timestamp of the last update
    uint256 public lastTimestamp;
    // Volatility threshold (e.g., 50000 means 5%, scaled by 1e6)
    uint256 public volatilityThreshold;

    event NVIUpdated(int256 newNVI, uint256 timestamp);

    /// @notice Initializes the contract with initial price, volume, and volatility threshold.
    /// @param initialPrice The initial price (scaled by 1e18).
    /// @param initialVolume The initial volume.
    /// @param _volatilityThreshold The threshold (scaled by 1e6) for minimum absolute price change to update NVI.
    constructor(uint256 initialPrice, uint256 initialVolume, uint256 _volatilityThreshold) {
        require(initialPrice > 0 && initialVolume > 0, "Initial values must be > 0");
        nvi = 1000 * 1e18; // starting NVI value
        lastPrice = initialPrice;
        lastVolume = initialVolume;
        lastTimestamp = block.timestamp;
        volatilityThreshold = _volatilityThreshold;
    }

    /// @notice Updates the NVI daily based on current price and volume.
    ///         If the current trading volume is lower than the previous day's volume,
    ///         and if the absolute percentage price change exceeds the volatility threshold,
    ///         then the NVI is updated based on the price change.
    /// @param currentPrice The current price (scaled by 1e18).
    /// @param currentVolume The current volume.
    function updateData(uint256 currentPrice, uint256 currentVolume) external {
        require(currentPrice > 0, "Price must be > 0");
        require(block.timestamp >= lastTimestamp + 1 days, "Update allowed once per day");

        // Check if the current volume is lower than the last volume.
        if (currentVolume < lastVolume) {
            // Calculate the price change percentage (scaled by 1e18):
            // priceChange = (currentPrice - lastPrice) / lastPrice, scaled by 1e18.
            int256 priceChange = (int256(currentPrice) - int256(lastPrice)) * 1e18 / int256(lastPrice);
            // Compute the absolute value of priceChange.
            int256 absPriceChange = priceChange < 0 ? -priceChange : priceChange;
            // Only update NVI if absolute price change exceeds the volatility threshold.
            if (absPriceChange >= int256(volatilityThreshold)) {
                // newNVI = oldNVI * (1 + priceChange)
                nvi = (nvi * (int256(1e18) + priceChange)) / int256(1e18);
            }
        }
        // Update historical data for next cycle.
        lastPrice = currentPrice;
        lastVolume = currentVolume;
        lastTimestamp = block.timestamp;
        emit NVIUpdated(nvi, block.timestamp);
    }

    /// @notice Returns the current Negative Volume Index (NVI).
    function getNVI() external view returns (int256) {
        return nvi;
    }
}
