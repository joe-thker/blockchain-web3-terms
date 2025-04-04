// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Golden Cross Tracker
contract GoldenCrossTracker {
    uint256[] public prices; // daily prices (e.g., from oracles or off-chain feed)

    uint256 public shortWindow = 5;  // simulate 5-day MA
    uint256 public longWindow = 10; // simulate 10-day MA

    event NewPrice(uint256 price);
    event GoldenCross(uint256 timestamp, uint256 shortMA, uint256 longMA);
    event DeathCross(uint256 timestamp, uint256 shortMA, uint256 longMA);

    function pushPrice(uint256 price) external {
        prices.push(price);
        emit NewPrice(price);

        if (prices.length >= longWindow) {
            uint256 shortMA = calcMA(shortWindow);
            uint256 longMA = calcMA(longWindow);

            if (shortMA > longMA) {
                emit GoldenCross(block.timestamp, shortMA, longMA);
            } else if (shortMA < longMA) {
                emit DeathCross(block.timestamp, shortMA, longMA);
            }
        }
    }

    function calcMA(uint256 window) public view returns (uint256 avg) {
        require(prices.length >= window, "Not enough data");

        uint256 sum;
        for (uint256 i = prices.length - window; i < prices.length; i++) {
            sum += prices[i];
        }
        return sum / window;
    }

    function getLatestPrice() external view returns (uint256) {
        require(prices.length > 0, "No prices");
        return prices[prices.length - 1];
    }

    function getAllPrices() external view returns (uint256[] memory) {
        return prices;
    }
}
