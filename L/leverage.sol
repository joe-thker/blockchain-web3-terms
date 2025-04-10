// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Leverage Position Simulator
/// @notice Simulates opening/closing leveraged long positions using borrowed funds
contract LeverageSimulator {
    address public owner;
    uint256 public collateral;
    uint256 public debt;
    uint256 public positionSize;
    uint256 public leverageRatio;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice Open a leveraged position (e.g., 3x = 300% exposure)
    function openPosition(uint256 _collateral, uint256 _leverageX) external onlyOwner {
        require(_leverageX >= 1 && _leverageX <= 10, "Leverage out of bounds");

        collateral = _collateral;
        leverageRatio = _leverageX;
        positionSize = _collateral * _leverageX;
        debt = positionSize - _collateral;
    }

    /// @notice Close position and calculate outcome
    function closePosition(uint256 newPriceRatio) external onlyOwner returns (int256 pnl) {
        // Price ratio simulates profit/loss multiplier (e.g., 120 = +20%)
        require(newPriceRatio > 0, "Invalid price");

        uint256 newValue = (positionSize * newPriceRatio) / 100;
        int256 valueAfterDebt = int256(newValue) - int256(debt);
        pnl = valueAfterDebt - int256(collateral);

        // Reset position
        collateral = 0;
        debt = 0;
        positionSize = 0;
        leverageRatio = 0;
    }
}
