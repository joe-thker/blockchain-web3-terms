// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NegativeVolumeIndex_Trend
/// @notice Computes a simple moving average (trend) of NVI alongside its daily update.
contract NegativeVolumeIndex_Trend {
    int256 public nvi; // current NVI (scaled by 1e18)
    int256 public nviTrend; // moving average of NVI (trend)
    uint256 public lastPrice;
    uint256 public lastVolume;
    uint256 public lastTimestamp;
    uint256 public windowSize; // number of days for moving average
    int256[] public historicalNVI;

    event NVIUpdated(int256 newNVI, uint256 timestamp);

    constructor(uint256 initialPrice, uint256 initialVolume, uint256 _windowSize) {
        require(initialPrice > 0 && initialVolume > 0, "Initial values >0 required");
        nvi = 1000 * 1e18;
        lastPrice = initialPrice;
        lastVolume = initialVolume;
        lastTimestamp = block.timestamp;
        windowSize = _windowSize;
        historicalNVI.push(nvi);
        nviTrend = nvi;
    }

    /// @notice Update the NVI and recalc moving average if applicable.
    function updateData(uint256 currentPrice, uint256 currentVolume) external {
        require(currentPrice > 0, "Price must be > 0");
        require(block.timestamp >= lastTimestamp + 1 days, "Update once per day");

        if (currentVolume < lastVolume) {
            int256 priceChange = (int256(currentPrice) - int256(lastPrice)) * 1e18 / int256(lastPrice);
            nvi = (nvi * (int256(1e18) + priceChange)) / int256(1e18);
        }
        // Update historical array
        historicalNVI.push(nvi);
        if (historicalNVI.length > windowSize) {
            // Remove oldest entry by shifting array index (not gas-efficient; in production use a circular buffer)
            delete historicalNVI[0];
        }
        // Calculate trend as average of available NVI history.
        int256 sum = 0;
        uint256 count = historicalNVI.length;
        for (uint256 i = 0; i < count; i++) {
            sum += historicalNVI[i];
        }
        nviTrend = sum / int256(count);

        lastPrice = currentPrice;
        lastVolume = currentVolume;
        lastTimestamp = block.timestamp;

        emit NVIUpdated(nvi, block.timestamp);
    }

    function getNVI() external view returns (int256) {
        return nvi;
    }

    function getTrend() external view returns (int256) {
        return nviTrend;
    }
}
