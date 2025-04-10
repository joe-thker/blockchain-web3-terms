// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/// @title Simple Lending + Liquidation System
contract LiquidationVault {
    IERC20 public collateralToken;
    IERC20 public debtToken;

    struct Position {
        uint256 collateralAmount; // in tokens
        uint256 debtAmount;       // in tokens
    }

    mapping(address => Position) public positions;
    address public oracle;
    uint256 public collateralPrice = 1000; // example: 1 token = $1,000
    uint256 public debtPrice = 100;        // example: 1 token = $100

    event Liquidated(address indexed user, address indexed liquidator, uint256 repayAmount, uint256 seizedCollateral);

    constructor(address _collateral, address _debt, address _oracle) {
        collateralToken = IERC20(_collateral);
        debtToken = IERC20(_debt);
        oracle = _oracle;
    }

    function depositCollateral(uint256 amount) external {
        require(collateralToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        positions[msg.sender].collateralAmount += amount;
    }

    function borrow(uint256 amount) external {
        Position storage pos = positions[msg.sender];
        require(pos.collateralAmount > 0, "No collateral");

        uint256 maxBorrow = (pos.collateralAmount * collateralPrice * 50) / (100 * debtPrice); // 50% LTV
        require(pos.debtAmount + amount <= maxBorrow, "Too much debt");

        positions[msg.sender].debtAmount += amount;
        require(debtToken.transfer(msg.sender, amount), "Debt transfer failed");
    }

    function liquidate(address user, uint256 repayAmount) external {
        Position storage pos = positions[user];
        require(pos.debtAmount > 0, "No debt");

        uint256 collateralValue = pos.collateralAmount * collateralPrice;
        uint256 debtValue = pos.debtAmount * debtPrice;

        require(collateralValue * 100 < debtValue * 75, "Not eligible for liquidation"); // Liquidation threshold: 75% LTV

        // Calculate how much collateral to seize
        uint256 seizeAmount = (repayAmount * debtPrice * 110) / (100 * collateralPrice); // 10% liquidation bonus

        require(seizeAmount <= pos.collateralAmount, "Not enough collateral");

        require(debtToken.transferFrom(msg.sender, address(this), repayAmount), "Repay failed");

        pos.debtAmount -= repayAmount;
        pos.collateralAmount -= seizeAmount;

        require(collateralToken.transfer(msg.sender, seizeAmount), "Collateral transfer failed");

        emit Liquidated(user, msg.sender, repayAmount, seizeAmount);
    }
}
