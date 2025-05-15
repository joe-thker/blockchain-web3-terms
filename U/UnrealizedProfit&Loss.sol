// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title UnrealizedPnLTracker - Track user's open position PnL using an oracle
interface IOracle {
    function getETHPriceUSD() external view returns (uint256); // 1 ETH = ? USD (1e8 decimals)
}

contract UnrealizedPnLTracker {
    struct Position {
        uint256 ethAmount;       // in wei
        uint256 entryPriceUSD;   // oracle price at time of deposit (1e8)
        bool isOpen;
    }

    mapping(address => Position) public positions;
    IOracle public priceOracle;

    event PositionOpened(address indexed user, uint256 amountETH, uint256 entryPrice);
    event PositionClosed(address indexed user, int256 pnlUSD);

    constructor(address _oracle) {
        priceOracle = IOracle(_oracle);
    }

    function openPosition() external payable {
        require(msg.value > 0, "No ETH sent");
        require(!positions[msg.sender].isOpen, "Position already open");

        uint256 entryPrice = priceOracle.getETHPriceUSD(); // e.g., 2000 * 1e8

        positions[msg.sender] = Position({
            ethAmount: msg.value,
            entryPriceUSD: entryPrice,
            isOpen: true
        });

        emit PositionOpened(msg.sender, msg.value, entryPrice);
    }

    function getUnrealizedPnLUSD(address user) public view returns (int256) {
        Position memory pos = positions[user];
        if (!pos.isOpen) return 0;

        uint256 currentPrice = priceOracle.getETHPriceUSD(); // e.g., 2100 * 1e8

        uint256 entryValue = (pos.ethAmount * pos.entryPriceUSD) / 1e18; // 1e8 result
        uint256 currentValue = (pos.ethAmount * currentPrice) / 1e18;    // 1e8 result

        return int256(currentValue) - int256(entryValue);
    }

    function closePosition() external {
        Position storage pos = positions[msg.sender];
        require(pos.isOpen, "No open position");

        int256 pnl = getUnrealizedPnLUSD(msg.sender);
        pos.isOpen = false;

        payable(msg.sender).transfer(pos.ethAmount);
        emit PositionClosed(msg.sender, pnl);
    }

    receive() external payable {}
}
