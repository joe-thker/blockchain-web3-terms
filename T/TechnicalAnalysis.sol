// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TrendAnalysisModule - Attack and Defense Simulation of On-Chain TA/Trend Systems

// ==============================
// 🧮 TA Oracle With TWAP + History
// ==============================
contract TAOracle {
    uint256[] public prices;
    uint256 public currentPrice;

    function setPrice(uint256 price) external {
        currentPrice = price;
        prices.push(price);
    }

    function getPrice() external view returns (uint256) {
        return currentPrice;
    }

    function getSMA(uint256 period) external view returns (uint256) {
        require(prices.length >= period, "Not enough data");
        uint256 sum;
        for (uint256 i = prices.length - period; i < prices.length; i++) {
            sum += prices[i];
        }
        return sum / period;
    }

    function getVolatility(uint256 window) external view returns (uint256) {
        uint256 count = window > prices.length ? prices.length : window;
        uint256 sum;
        uint256 max = 0;
        uint256 min = type(uint256).max;

        for (uint256 i = prices.length - count; i < prices.length; i++) {
            uint256 p = prices[i];
            if (p > max) max = p;
            if (p < min) min = p;
            sum += p;
        }

        return max - min;
    }
}

// ==============================
// 🔓 Vulnerable Trend Analyzer
// ==============================
interface ITAOracle {
    function getPrice() external view returns (uint256);
    function getSMA(uint256) external view returns (uint256);
}

contract TrendAnalyzer {
    ITAOracle public oracle;
    uint256 public shortMA = 3;
    uint256 public longMA = 7;

    enum Trend { Neutral, Bullish, Bearish }
    Trend public currentTrend;

    event TrendUpdated(Trend trend);

    constructor(address _oracle) {
        oracle = ITAOracle(_oracle);
        currentTrend = Trend.Neutral;
    }

    function checkTrend() external {
        uint256 shortAvg = oracle.getSMA(shortMA);
        uint256 longAvg = oracle.getSMA(longMA);

        if (shortAvg > longAvg) {
            currentTrend = Trend.Bullish;
        } else if (shortAvg < longAvg) {
            currentTrend = Trend.Bearish;
        } else {
            currentTrend = Trend.Neutral;
        }

        emit TrendUpdated(currentTrend);
    }
}

// ==============================
// 🔓 TA Oracle Spoofing Attacker
// ==============================
interface ITAOracleSet {
    function setPrice(uint256) external;
}

contract TAOracleSpoofer {
    ITAOracleSet public oracle;

    constructor(address _oracle) {
        oracle = ITAOracleSet(_oracle);
    }

    function spoofBullish() external {
        oracle.setPrice(3000 ether); // Fake high price to trigger bullish crossover
    }

    function spoofBearish() external {
        oracle.setPrice(900 ether); // Fake low price to simulate crash
    }
}

// ==============================
// 🔐 Safe Trend Analyzer With Volatility Guard
// ==============================
interface ITASecureOracle {
    function getPrice() external view returns (uint256);
    function getSMA(uint256) external view returns (uint256);
    function getVolatility(uint256) external view returns (uint256);
}

contract SafeTrendAnalyzer {
    ITASecureOracle public oracle;
    uint256 public shortMA = 3;
    uint256 public longMA = 7;
    uint256 public lastUpdateBlock;
    uint256 public constant CONFIRM_DELAY = 5;

    enum Trend { Neutral, Bullish, Bearish }
    Trend public confirmedTrend;

    event ConfirmedTrend(Trend trend);

    constructor(address _oracle) {
        oracle = ITASecureOracle(_oracle);
    }

    function checkAndConfirmTrend() external {
        require(block.number > lastUpdateBlock + CONFIRM_DELAY, "Too soon");

        uint256 shortAvg = oracle.getSMA(shortMA);
        uint256 longAvg = oracle.getSMA(longMA);
        uint256 volatility = oracle.getVolatility(5);

        require(volatility < 1000 ether, "Volatility too high — reject trend");

        if (shortAvg > longAvg) {
            confirmedTrend = Trend.Bullish;
        } else if (shortAvg < longAvg) {
            confirmedTrend = Trend.Bearish;
        } else {
            confirmedTrend = Trend.Neutral;
        }

        lastUpdateBlock = block.number;
        emit ConfirmedTrend(confirmedTrend);
    }
}
