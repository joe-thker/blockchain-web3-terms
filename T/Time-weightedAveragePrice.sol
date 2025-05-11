// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TWAPModule - Time-Weighted Average Price Oracle with Attack and Defense Simulation

// ==============================
// 🔓 Vulnerable TWAP Oracle
// ==============================
contract TWAPOracle {
    struct PricePoint {
        uint256 price;
        uint256 timestamp;
    }

    PricePoint[] public history;
    uint256 public windowSize = 5 minutes;

    function pushPrice(uint256 price) external {
        history.push(PricePoint(price, block.timestamp));
    }

    function getTWAP() external view returns (uint256) {
        uint256 sum;
        uint256 count;
        uint256 nowT = block.timestamp;
        for (uint256 i = 0; i < history.length; i++) {
            if (nowT - history[i].timestamp <= windowSize) {
                sum += history[i].price;
                count++;
            }
        }
        return count > 0 ? sum / count : 0;
    }
}

// ==============================
// 🔓 Attacker: TWAP Spike Manipulator
// ==============================
interface ITWAPOracle {
    function pushPrice(uint256) external;
}

contract TWAPSpikerAttack {
    ITWAPOracle public oracle;

    constructor(address _oracle) {
        oracle = ITWAPOracle(_oracle);
    }

    function spikePrice(uint256 fakePrice) external {
        oracle.pushPrice(fakePrice);
    }
}

// ==============================
// 🔐 Safe TWAP Oracle With Filtering
// ==============================
contract SafeTWAPOracle {
    struct PricePoint {
        uint256 price;
        uint256 timestamp;
    }

    PricePoint[] public history;
    uint256 public windowSize = 5 minutes;
    uint256 public lastUpdate;
    uint256 public volatilityLimit = 2 ether; // max jump allowed
    uint256 public minInterval = 60; // min 60s between updates

    event PriceUpdated(uint256 price);

    function pushPrice(uint256 price) external {
        require(block.timestamp > lastUpdate + minInterval, "Too soon");
        if (history.length > 0) {
            uint256 lastPrice = history[history.length - 1].price;
            uint256 delta = price > lastPrice ? price - lastPrice : lastPrice - price;
            require(delta <= volatilityLimit, "Too volatile");
        }

        history.push(PricePoint(price, block.timestamp));
        lastUpdate = block.timestamp;
        emit PriceUpdated(price);
    }

    function getTWAP() external view returns (uint256) {
        uint256 sum;
        uint256 count;
        uint256 nowT = block.timestamp;
        for (uint256 i = 0; i < history.length; i++) {
            if (nowT - history[i].timestamp <= windowSize) {
                sum += history[i].price;
                count++;
            }
        }
        return count > 0 ? sum / count : 0;
    }
}

// ==============================
// 📈 External Spot Oracle (For Drift Detection)
// ==============================
contract ExternalSpotOracle {
    uint256 public latest;

    function setPrice(uint256 price) external {
        latest = price;
    }

    function getSpot() external view returns (uint256) {
        return latest;
    }
}
