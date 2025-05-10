// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TechnicalIndicatorsModule - On-chain TA Indicators with Attack and Defense Simulation

// ==============================
// 📊 Technical Indicator Oracle
// ==============================
contract IndicatorOracle {
    uint256[] public prices;
    uint256 public lastEMA;
    uint256 public smoothing = 2; // for EMA

    function pushPrice(uint256 price) external {
        prices.push(price);
        // Update EMA
        if (lastEMA == 0) {
            lastEMA = price;
        } else {
            lastEMA = (price * smoothing + lastEMA * (10 - smoothing)) / 10;
        }
    }

    function getSMA(uint256 window) public view returns (uint256) {
        require(prices.length >= window, "Not enough data");
        uint256 sum;
        for (uint256 i = prices.length - window; i < prices.length; i++) {
            sum += prices[i];
        }
        return sum / window;
    }

    function getEMA() public view returns (uint256) {
        return lastEMA;
    }

    function getRSI(uint256 window) public view returns (uint256) {
        require(prices.length > window, "Not enough history");
        uint256 gain;
        uint256 loss;
        for (uint256 i = prices.length - window; i < prices.length - 1; i++) {
            int256 diff = int256(prices[i + 1]) - int256(prices[i]);
            if (diff > 0) gain += uint256(diff);
            else loss += uint256(-diff);
        }
        if (loss == 0) return 100;
        uint256 rs = (gain * 100) / loss;
        return 100 - (10000 / (100 + rs));
    }

    function getVolatility(uint256 window) public view returns (uint256) {
        uint256 count = window > prices.length ? prices.length : window;
        uint256 maxP = 0;
        uint256 minP = type(uint256).max;
        for (uint256 i = prices.length - count; i < prices.length; i++) {
            if (prices[i] > maxP) maxP = prices[i];
            if (prices[i] < minP) minP = prices[i];
        }
        return maxP - minP;
    }
}

// ==============================
// 🔓 Vulnerable RSI Trading Bot
// ==============================
interface IRsiOracle {
    function getRSI(uint256) external view returns (uint256);
}

contract BasicTradingBot {
    enum Position { None, Long, Short }
    Position public currentPosition;

    IRsiOracle public oracle;
    address public owner;

    constructor(address _oracle) {
        oracle = IRsiOracle(_oracle);
        owner = msg.sender;
    }

    function checkRSI() external {
        uint256 rsi = oracle.getRSI(5);
        if (rsi < 30) currentPosition = Position.Long;
        else if (rsi > 70) currentPosition = Position.Short;
        else currentPosition = Position.None;
    }
}

// ==============================
// 🔓 Spoofer Attack (Fake RSI Signals)
// ==============================
interface IIndicatorOracleSet {
    function pushPrice(uint256) external;
}

contract SpoofIndicatorAttacker {
    IIndicatorOracleSet public oracle;

    constructor(address _oracle) {
        oracle = IIndicatorOracleSet(_oracle);
    }

    function spoofBullish() external {
        oracle.pushPrice(10000 ether);
    }

    function spoofBearish() external {
        oracle.pushPrice(1 ether);
    }
}

// ==============================
// 🔐 Safe Trading Bot with Confirmed RSI + Volatility Filter
// ==============================
interface IRsiVolOracle {
    function getRSI(uint256) external view returns (uint256);
    function getVolatility(uint256) external view returns (uint256);
}

contract SafeTradingBot {
    enum Position { None, Long, Short }
    Position public currentPosition;
    address public owner;
    IRsiVolOracle public oracle;

    uint256 public constant MAX_VOL = 500 ether;
    uint256 public constant CONFIRM_BLOCKS = 5;
    mapping(Position => uint256) public confirmBlock;

    constructor(address _oracle) {
        oracle = IRsiVolOracle(_oracle);
        owner = msg.sender;
    }

    function checkSafeRSI() external {
        uint256 rsi = oracle.getRSI(5);
        uint256 vol = oracle.getVolatility(5);
        require(vol < MAX_VOL, "High volatility — signal blocked");

        Position trend;
        if (rsi < 30) trend = Position.Long;
        else if (rsi > 70) trend = Position.Short;
        else trend = Position.None;

        if (block.number > confirmBlock[trend] + CONFIRM_BLOCKS) {
            currentPosition = trend;
            confirmBlock[trend] = block.number;
        }
    }
}
