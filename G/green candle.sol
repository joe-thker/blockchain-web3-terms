// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Green Candle Detector
contract CandleTracker {
    struct Candle {
        uint256 timestamp;
        uint256 open;
        uint256 close;
        uint256 high;
        uint256 low;
    }

    Candle[] public candles;
    uint256 public greenCount;
    uint256 public redCount;

    event CandleAdded(uint256 open, uint256 close, bool isGreen);

    /// @notice Add a new candle
    function addCandle(uint256 open, uint256 close, uint256 high, uint256 low) external {
        require(high >= open && high >= close, "Invalid high");
        require(low <= open && low <= close, "Invalid low");

        Candle memory newCandle = Candle({
            timestamp: block.timestamp,
            open: open,
            close: close,
            high: high,
            low: low
        });

        candles.push(newCandle);

        bool isGreen = close > open;
        if (isGreen) greenCount++;
        else if (close < open) redCount++;

        emit CandleAdded(open, close, isGreen);
    }

    /// @notice Returns latest candle info
    function latestCandle() external view returns (Candle memory) {
        require(candles.length > 0, "No candles yet");
        return candles[candles.length - 1];
    }

    /// @notice Check if latest candle is green
    function isLastCandleGreen() external view returns (bool) {
        require(candles.length > 0, "No candles");
        Candle memory c = candles[candles.length - 1];
        return c.close > c.open;
    }

    function totalCandles() external view returns (uint256) {
        return candles.length;
    }
}
