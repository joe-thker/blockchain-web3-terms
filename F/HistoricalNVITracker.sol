// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NegativeVolumeIndex_Historical
/// @notice Records a history of daily NVI values and timestamps.
contract NegativeVolumeIndex_Historical {
    struct NVIRecord {
        int256 nvi;       // NVI value (scaled by 1e18)
        uint256 timestamp;
    }

    NVIRecord[] public history;

    int256 public nvi;
    uint256 public lastPrice;
    uint256 public lastVolume;
    uint256 public lastTimestamp;

    event NVIUpdated(int256 newNVI, uint256 timestamp);

    constructor(uint256 initialPrice, uint256 initialVolume) {
        require(initialPrice > 0 && initialVolume > 0, "Initial values required");
        nvi = 1000 * 1e18; // initial NVI
        lastPrice = initialPrice;
        lastVolume = initialVolume;
        lastTimestamp = block.timestamp;
        history.push(NVIRecord(nvi, block.timestamp));
    }

    /// @notice Update daily NVI and save record to history.
    function updateData(uint256 currentPrice, uint256 currentVolume) external {
        require(currentPrice > 0, "Price must be > 0");
        require(block.timestamp >= lastTimestamp + 1 days, "Update once per day");

        if (currentVolume < lastVolume) {
            int256 priceChange = (int256(currentPrice) - int256(lastPrice)) * 1e18 / int256(lastPrice);
            nvi = (nvi * (int256(1e18) + priceChange)) / int256(1e18);
        }
        // Save record
        history.push(NVIRecord(nvi, block.timestamp));
        lastPrice = currentPrice;
        lastVolume = currentVolume;
        lastTimestamp = block.timestamp;

        emit NVIUpdated(nvi, block.timestamp);
    }

    /// @notice Retrieve full historical data length.
    function getHistoryLength() external view returns (uint256) {
        return history.length;
    }
}
