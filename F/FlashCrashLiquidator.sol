// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FlashCrashLiquidator {
    struct Position {
        address user;
        uint256 collateral;
        uint256 debt;
    }

    mapping(address => Position) public positions;
    uint256 public liquidationRatio = 150; // e.g., 150%

    event Liquidated(address indexed user, uint256 collateral, uint256 debt);

    function openPosition(uint256 collateral, uint256 debt) external {
        positions[msg.sender] = Position(msg.sender, collateral, debt);
    }

    function reportPriceAndLiquidate(address user, uint256 price) external {
        Position memory p = positions[user];
        uint256 value = p.collateral * price;
        uint256 required = p.debt * liquidationRatio / 100;
        if (value < required) {
            delete positions[user];
            emit Liquidated(user, p.collateral, p.debt);
        }
    }
}
