// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SyntheticAssetModule - Attack & Defense for Synthetic Asset Protocols in Solidity

// ==============================
// 🧮 Mock Oracle with Price Feed
// ==============================
contract MockPriceOracle {
    uint256[] public priceHistory;
    uint256 public latest;

    function setPrice(uint256 price) external {
        latest = price;
        priceHistory.push(price);
    }

    function getLatestPrice() external view returns (uint256) {
        return latest;
    }

    function getAveragePrice(uint256 window) external view returns (uint256) {
        uint256 sum;
        uint256 count = window > priceHistory.length ? priceHistory.length : window;
        for (uint256 i = priceHistory.length - count; i < priceHistory.length; i++) {
            sum += priceHistory[i];
        }
        return count > 0 ? sum / count : latest;
    }
}

// ==============================
// 🔓 Vulnerable Synthetic Asset
// ==============================
interface IOracle {
    function getLatestPrice() external view returns (uint256);
}

contract SyntheticAsset {
    IOracle public oracle;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public collateral;

    uint256 public constant COLLATERAL_RATIO = 100; // 100% collateralized

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    function depositCollateral() external payable {
        collateral[msg.sender] += msg.value;
    }

    function mint() external {
        uint256 price = oracle.getLatestPrice();
        uint256 value = collateral[msg.sender] * price / 1 ether;
        balances[msg.sender] += value;
        collateral[msg.sender] = 0;
    }

    function burn(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        uint256 refund = amount * 1 ether / oracle.getLatestPrice();
        payable(msg.sender).transfer(refund);
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    receive() external payable {}
}

// ==============================
// 🔓 Oracle Manipulator (Attacker)
// ==============================
interface IOracleSet {
    function setPrice(uint256) external;
}

contract OracleManipulator {
    IOracleSet public oracle;

    constructor(address _oracle) {
        oracle = IOracleSet(_oracle);
    }

    function fakePump() external {
        oracle.setPrice(4000 ether); // spoofed high price
    }

    function crashBack() external {
        oracle.setPrice(1000 ether); // restore realistic price
    }
}

// ==============================
// 🔐 Hardened Synthetic Asset (Defense)
// ==============================
interface IOracleTWAP {
    function getLatestPrice() external view returns (uint256);
    function getAveragePrice(uint256 window) external view returns (uint256);
}

contract SafeSyntheticAsset {
    IOracleTWAP public oracle;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public collateral;
    uint256 public constant MIN_COLLATERAL_RATIO = 150; // 150%
    uint256 public constant TWAP_WINDOW = 5;

    constructor(address _oracle) {
        oracle = IOracleTWAP(_oracle);
    }

    function depositCollateral() external payable {
        collateral[msg.sender] += msg.value;
    }

    function mint() external {
        uint256 spot = oracle.getLatestPrice();
        uint256 avg = oracle.getAveragePrice(TWAP_WINDOW);

        require(spot <= avg * 105 / 100, "Price spike detected");

        uint256 value = collateral[msg.sender] * spot / 1 ether;
        uint256 allowed = (collateral[msg.sender] * 1 ether) / (MIN_COLLATERAL_RATIO * spot / 100);

        balances[msg.sender] += allowed;
        collateral[msg.sender] = 0;
    }

    function burn(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough synths");
        balances[msg.sender] -= amount;

        uint256 refund = amount * 1 ether / oracle.getLatestPrice();
        payable(msg.sender).transfer(refund);
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    receive() external payable {}
}
