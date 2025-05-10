// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TakeProfitModule - Automated Take Profit System with Attack and Defense in Solidity

// ==============================
// 🧮 Oracle With Spot & TWAP
// ==============================
contract MockOracleTWAP {
    uint256[] public priceHistory;
    uint256 public currentPrice;

    function setPrice(uint256 price) external {
        currentPrice = price;
        priceHistory.push(price);
    }

    function getPrice() external view returns (uint256) {
        return currentPrice;
    }

    function getAverage(uint256 blocksBack) external view returns (uint256) {
        uint256 sum;
        uint256 count = blocksBack > priceHistory.length ? priceHistory.length : blocksBack;
        for (uint256 i = priceHistory.length - count; i < priceHistory.length; i++) {
            sum += priceHistory[i];
        }
        return count > 0 ? sum / count : currentPrice;
    }
}

// ==============================
// 🔓 Simple Take Profit Bot (Vulnerable)
// ==============================
interface IOracle {
    function getPrice() external view returns (uint256);
}

contract TakeProfitBot {
    address public owner;
    IOracle public oracle;

    uint256 public entryPrice;
    uint256 public targetProfitPercent; // e.g., 120 = +20%
    bool public inPosition;

    constructor(address _oracle, uint256 _profitPercent) {
        owner = msg.sender;
        oracle = IOracle(_oracle);
        targetProfitPercent = _profitPercent;
    }

    function enterTrade() external {
        require(msg.sender == owner, "Not owner");
        require(!inPosition, "Already in position");
        entryPrice = oracle.getPrice();
        inPosition = true;
    }

    function checkTakeProfit() external {
        require(inPosition, "No position");
        uint256 price = oracle.getPrice();
        if (price >= entryPrice * targetProfitPercent / 100) {
            inPosition = false;
        }
    }
}

// ==============================
// 🔓 Oracle Manipulator
// ==============================
interface IOracleSet {
    function setPrice(uint256) external;
}

contract OracleManipulator {
    IOracleSet public oracle;

    constructor(address _oracle) {
        oracle = IOracleSet(_oracle);
    }

    function spoofHighPrice(uint256 fakeHigh) external {
        oracle.setPrice(fakeHigh);
    }

    function resetPrice(uint256 normal) external {
        oracle.setPrice(normal);
    }
}

// ==============================
// 🔐 Safe Take Profit Bot with TWAP, Delay & Lock
// ==============================
interface IOracleTWAP {
    function getPrice() external view returns (uint256);
    function getAverage(uint256 blocksBack) external view returns (uint256);
}

contract SafeTakeProfitBot {
    address public owner;
    IOracleTWAP public oracle;

    uint256 public entryPrice;
    uint256 public enterBlock;
    uint256 public targetProfitPercent;
    bool public inPosition;
    bool public triggered;

    uint256 public constant MIN_HOLD_BLOCKS = 5;
    uint256 public constant TWAP_WINDOW = 5;

    constructor(address _oracle, uint256 _profitPercent) {
        owner = msg.sender;
        oracle = IOracleTWAP(_oracle);
        targetProfitPercent = _profitPercent;
    }

    function enterTrade() external {
        require(msg.sender == owner, "Not owner");
        require(!inPosition, "In position");
        require(!triggered, "Already exited");

        entryPrice = oracle.getPrice();
        enterBlock = block.number;
        inPosition = true;
    }

    function checkTakeProfit() external {
        require(inPosition, "No position");
        require(block.number > enterBlock + MIN_HOLD_BLOCKS, "Hold longer");

        uint256 twap = oracle.getAverage(TWAP_WINDOW);
        if (twap >= entryPrice * targetProfitPercent / 100) {
            inPosition = false;
            triggered = true;
        }
    }
}
