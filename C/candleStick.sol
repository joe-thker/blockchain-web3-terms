// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CandlestickChart {
    address public owner;

    // Each candlestick represents price data for a specific time period.
    struct Candle {
        uint256 open;      // Opening price
        uint256 high;      // Highest price during the period
        uint256 low;       // Lowest price during the period
        uint256 close;     // Closing price
        uint256 volume;    // Trading volume during the period
        uint256 timestamp; // Timestamp for the candlestick period
    }

    // Array to store candlestick entries.
    Candle[] public candles;

    event CandleAdded(
        uint256 indexed index,
        uint256 open,
        uint256 high,
        uint256 low,
        uint256 close,
        uint256 volume,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Adds a new candlestick entry. Only the owner can add data.
    /// @param _open Opening price.
    /// @param _high Highest price.
    /// @param _low Lowest price.
    /// @param _close Closing price.
    /// @param _volume Trading volume.
    /// @param _timestamp Timestamp for the candlestick period.
    function addCandle(
        uint256 _open,
        uint256 _high,
        uint256 _low,
        uint256 _close,
        uint256 _volume,
        uint256 _timestamp
    ) external onlyOwner {
        // Basic validations to ensure candlestick integrity.
        require(_low <= _open && _low <= _close, "Low must be <= open and close");
        require(_high >= _open && _high >= _close, "High must be >= open and close");

        candles.push(Candle({
            open: _open,
            high: _high,
            low: _low,
            close: _close,
            volume: _volume,
            timestamp: _timestamp
        }));

        emit CandleAdded(candles.length - 1, _open, _high, _low, _close, _volume, _timestamp);
    }

    /// @notice Retrieves the candlestick data at a specific index.
    /// @param index The index of the candlestick.
    /// @return A Candle struct containing the candlestick data.
    function getCandle(uint256 index) external view returns (Candle memory) {
        require(index < candles.length, "Index out of range");
        return candles[index];
    }

    /// @notice Returns the total number of candlesticks stored.
    /// @return The count of candlestick entries.
    function getCandleCount() external view returns (uint256) {
        return candles.length;
    }
}
