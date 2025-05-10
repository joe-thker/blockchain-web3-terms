// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SwingTradingModule - Attack and Defense Solidity implementation for Swing Trading

// ==============================
// 📊 Oracle with Deviation Logic
// ==============================
contract DeviationOracle {
    uint256[] public priceHistory;
    uint256 public currentPrice;

    function setPrice(uint256 price) external {
        currentPrice = price;
        priceHistory.push(price);
    }

    function getPrice() external view returns (uint256) {
        return currentPrice;
    }

    function getPriceDeviation(uint256 blocksBack) external view returns (uint256) {
        uint256 count = blocksBack > priceHistory.length ? priceHistory.length : blocksBack;
        uint256 sum;
        for (uint256 i = priceHistory.length - count; i < priceHistory.length; i++) {
            sum += priceHistory[i];
        }
        uint256 avg = sum / count;
        uint256 diff = currentPrice > avg ? currentPrice - avg : avg - currentPrice;
        return diff * 1000 / avg; // Deviation in ‱ (permyriad)
    }
}

// ==============================
// 🤖 Vulnerable Swing Trader Bot
// ==============================
interface IOracle {
    function getPrice() external view returns (uint256);
}

contract SwingTraderBot {
    IOracle public oracle;
    address public owner;

    enum Position { None, Long }
    Position public currentPosition;

    uint256 public entryPrice;
    uint256 public lastTradeBlock;

    uint256 public takeProfit = 1100; // +10%
    uint256 public stopLoss = 900;    // -10%
    uint256 public cooldownBlocks = 5;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
        owner = msg.sender;
    }

    function enterTrade() external onlyOwner {
        require(currentPosition == Position.None, "Already in trade");
        require(block.number > lastTradeBlock + cooldownBlocks, "Cooldown active");

        entryPrice = oracle.getPrice();
        currentPosition = Position.Long;
        lastTradeBlock = block.number;
    }

    function checkExit() external onlyOwner {
        require(currentPosition == Position.Long, "No active position");

        uint256 price = oracle.getPrice();
        if (price >= entryPrice * takeProfit / 1000 || price <= entryPrice * stopLoss / 1000) {
            currentPosition = Position.None;
        }
    }
}

// ==============================
// 🧨 Swing Trap Attack Contract
// ==============================
interface IOracleSettable {
    function setPrice(uint256) external;
}

contract SwingTrapAttack {
    IOracleSettable public oracle;
    address public swingBot;

    constructor(address _oracle, address _bot) {
        oracle = IOracleSettable(_oracle);
        swingBot = _bot;
    }

    function manipulateToTriggerEntry() external {
        oracle.setPrice(1100); // Fake bullish crossover
    }

    function reverseImmediately() external {
        oracle.setPrice(850); // Dump to trigger stop-loss
    }
}

// ==============================
// 🛡️ Secure Swing Trader Defense
// ==============================
interface IPriceOracle {
    function getPrice() external view returns (uint256);
    function getPriceDeviation(uint256 blocks) external view returns (uint256);
}

contract SafeSwingTrader {
    IPriceOracle public oracle;
    address public owner;
    uint256 public entryPrice;
    uint256 public lastTradeBlock;
    uint256 public cooldownBlocks = 10;
    bool public inPosition;

    constructor(address _oracle) {
        oracle = IPriceOracle(_oracle);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized");
        _;
    }

    function enterIfStable() external onlyOwner {
        require(!inPosition, "Already in trade");
        require(block.number > lastTradeBlock + cooldownBlocks, "Cooldown");

        uint256 deviation = oracle.getPriceDeviation(10);
        require(deviation < 50, "Too volatile"); // Deviation < 5%

        entryPrice = oracle.getPrice();
        inPosition = true;
        lastTradeBlock = block.number;
    }

    function exit() external onlyOwner {
        require(inPosition, "No trade");
        inPosition = false;
    }
}
