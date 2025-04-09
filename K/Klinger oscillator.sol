// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Klinger Oscillator (Simplified On-Chain)
/// @notice Simulates basic KVO logic using fixed-point math
contract KlingerOscillator {
    uint256 public shortEMA; // short-term EMA (e.g., 34)
    uint256 public longEMA;  // long-term EMA (e.g., 55)
    uint256 public klingerValue;

    uint256 constant multiplier = 1e6; // to simulate floating point

    event KlingerUpdated(uint256 volumeForce, uint256 klinger);

    constructor() {
        shortEMA = 0;
        longEMA = 0;
        klingerValue = 0;
    }

    function updateKlinger(
        uint256 high,
        uint256 low,
        uint256 close,
        uint256 volume
    ) external {
        require(high >= low, "Invalid high/low");

        uint256 trend = (2 * close - low - high) * volume / (high - low + 1); // Volume Force

        // Simulate EMA calculation (simplified)
        shortEMA = (trend * 2 + shortEMA * (34 - 1)) / 34;
        longEMA = (trend * 2 + longEMA * (55 - 1)) / 55;

        // Klinger Oscillator = shortEMA - longEMA
        if (shortEMA >= longEMA) {
            klingerValue = shortEMA - longEMA;
        } else {
            klingerValue = 0; // below zero can be tracked with signed int in advanced version
        }

        emit KlingerUpdated(trend, klingerValue);
    }

    function getKlinger() external view returns (uint256) {
        return klingerValue;
    }
}
