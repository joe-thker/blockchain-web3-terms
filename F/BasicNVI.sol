// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NegativeVolumeIndex_Basic
/// @notice A simplified Negative Volume Index (NVI) that updates once per day.
///         If today's trading volume is lower than yesterday's, the NVI is updated
///         based on the price change. Otherwise, it remains unchanged.
///         All values are scaled by 1e18 for precision.
contract NegativeVolumeIndex_Basic {
    int256 public nvi;         // NVI value (scaled by 1e18)
    uint256 public lastPrice;    // Last recorded price (scaled by 1e18)
    uint256 public lastVolume;   // Last recorded volume
    uint256 public lastTimestamp;
    
    event NVIUpdated(int256 newNVI, uint256 timestamp);

    /// @notice Constructor: set initial price, volume, and NVI (default 1000 * 1e18)
    constructor(uint256 initialPrice, uint256 initialVolume) {
        require(initialPrice > 0 && initialVolume > 0, "Initial values > 0 required");
        nvi = 1000 * 1e18; // initial NVI value
        lastPrice = initialPrice;
        lastVolume = initialVolume;
        lastTimestamp = block.timestamp;
    }

    /// @notice Update the NVI based on current price and volume.
    ///         Should be called roughly once per day.
    function updateData(uint256 currentPrice, uint256 currentVolume) external {
        require(currentPrice > 0, "Price must be > 0");
        // Allow update only once per day.
        require(block.timestamp >= lastTimestamp + 1 days, "Update only once per day");

        if (currentVolume < lastVolume) {
            // Calculate price change percentage: (currentPrice - lastPrice) / lastPrice, scaled by 1e18.
            int256 priceChange = (int256(currentPrice) - int256(lastPrice)) * 1e18 / int256(lastPrice);
            // Update NVI: newNVI = oldNVI * (1 + priceChange)
            nvi = (nvi * (int256(1e18) + priceChange)) / int256(1e18);
        }
        // Else: NVI remains unchanged.

        // Update stored values.
        lastPrice = currentPrice;
        lastVolume = currentVolume;
        lastTimestamp = block.timestamp;

        emit NVIUpdated(nvi, block.timestamp);
    }

    /// @notice Returns the current NVI.
    function getNVI() external view returns (int256) {
        return nvi;
    }
}
