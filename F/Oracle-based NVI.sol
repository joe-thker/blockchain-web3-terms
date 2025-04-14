// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPriceOracle {
    /// @notice Returns token price scaled by 1e18
    function getPrice() external view returns (uint256);
}

interface IVolumeOracle {
    /// @notice Returns trading volume for the day (scaled, unit depends on context)
    function getVolume() external view returns (uint256);
}

/// @title NegativeVolumeIndex_Oracle
/// @notice Uses external oracles to update the NVI automatically.
contract NegativeVolumeIndex_Oracle {
    IPriceOracle public priceOracle;
    IVolumeOracle public volumeOracle;

    int256 public nvi;
    uint256 public lastPrice;
    uint256 public lastVolume;
    uint256 public lastTimestamp;

    event NVIUpdated(int256 newNVI, uint256 timestamp);

    constructor(address _priceOracle, address _volumeOracle, uint256 initialPrice, uint256 initialVolume) {
        require(initialPrice > 0 && initialVolume > 0, "Initial values required");
        priceOracle = IPriceOracle(_priceOracle);
        volumeOracle = IVolumeOracle(_volumeOracle);
        nvi = 1000 * 1e18; // Initial NVI
        lastPrice = initialPrice;
        lastVolume = initialVolume;
        lastTimestamp = block.timestamp;
    }

    /// @notice Updates NVI using oracle data. Should be called daily.
    function updateNVI() external {
        require(block.timestamp >= lastTimestamp + 1 days, "Update once per day");
        uint256 currentPrice = priceOracle.getPrice();
        uint256 currentVolume = volumeOracle.getVolume();

        if (currentVolume < lastVolume) {
            int256 priceChange = (int256(currentPrice) - int256(lastPrice)) * 1e18 / int256(lastPrice);
            nvi = (nvi * (int256(1e18) + priceChange)) / int256(1e18);
        }

        lastPrice = currentPrice;
        lastVolume = currentVolume;
        lastTimestamp = block.timestamp;
        emit NVIUpdated(nvi, block.timestamp);
    }

    function getNVI() external view returns (int256) {
        return nvi;
    }
}
