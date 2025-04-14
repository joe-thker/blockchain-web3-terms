// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NegativeVolumeIndex
/// @notice This contract calculates a simplified version of the Negative Volume Index (NVI).
///         If today’s trading volume is lower than yesterday’s, the NVI is updated using the percentage price change.
///         Otherwise, the NVI remains unchanged.
///         The NVI is scaled by 1e18 for precision.
contract NegativeVolumeIndex {
    // NVI is stored as a signed integer for proper calculation of percentage changes.
    int256 public nvi;
    // Last recorded price (in an arbitrary unit, e.g., with 18 decimals).
    uint256 public lastPrice;
    // Last recorded volume.
    uint256 public lastVolume;
    // Timestamp of the last update.
    uint256 public lastTimestamp;

    // Event emitted when the NVI is updated.
    event NVIUpdated(int256 newNVI, uint256 timestamp);

    /// @notice Constructor sets the initial price and volume, and initializes NVI to 1000 (scaled by 1e18).
    /// @param initialPrice The initial price, must be > 0.
    /// @param initialVolume The initial volume, must be > 0.
    constructor(uint256 initialPrice, uint256 initialVolume) {
        require(initialPrice > 0 && initialVolume > 0, "Initial values must be > 0");
        // Set initial NVI to 1000 (scaled by 1e18)
        nvi = 1000 * 1e18;
        lastPrice = initialPrice;
        lastVolume = initialVolume;
        lastTimestamp = block.timestamp;
    }

    /// @notice Updates the Negative Volume Index (NVI) based on current price and volume.
    ///         This function is intended to be called once per day.
    /// @param currentPrice The current trading price (must be > 0).
    /// @param currentVolume The current trading volume.
    function updateData(uint256 currentPrice, uint256 currentVolume) external {
        require(currentPrice > 0, "Price must be > 0");
        // Ensure at least one day has passed since the last update
        require(block.timestamp >= lastTimestamp + 1 days, "Update allowed once per day");

        // If current volume is lower than the previous volume, update NVI.
        if (currentVolume < lastVolume) {
            // Calculate price change percentage (scaled by 1e18):
            // priceChange = (currentPrice - lastPrice) / lastPrice
            int256 priceChange = (int256(currentPrice) - int256(lastPrice)) * 1e18 / int256(lastPrice);
            // Update NVI: newNVI = oldNVI * (1 + priceChange)
            nvi = (nvi * (int256(1e18) + priceChange)) / int256(1e18);
        }
        // Else, NVI remains unchanged.

        // Update stored values for the next update cycle.
        lastPrice = currentPrice;
        lastVolume = currentVolume;
        lastTimestamp = block.timestamp;

        emit NVIUpdated(nvi, block.timestamp);
    }

    /// @notice Returns the current Negative Volume Index.
    function getNVI() external view returns (int256) {
        return nvi;
    }
}
