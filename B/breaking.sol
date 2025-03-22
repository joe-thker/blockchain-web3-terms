// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BreakingIndicator
/// @notice A contract that detects "break" events when price crosses defined support or resistance levels.
/// It is intended to simulate the idea of a breakout indicator in crypto markets.
contract BreakingIndicator {
    address public owner;
    address public priceUpdater; // Authorized address (e.g., an oracle) allowed to update prices.

    // Price thresholds (in wei or in the chosen unit for the asset price).
    uint256 public supportLevel;
    uint256 public resistanceLevel;

    // Last recorded price.
    uint256 public lastPrice;

    // Events to log break events.
    event UpwardBreak(uint256 newPrice, uint256 resistanceLevel);
    event DownwardBreak(uint256 newPrice, uint256 supportLevel);
    event PriceUpdated(uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }
    
    modifier onlyPriceUpdater() {
        require(msg.sender == priceUpdater, "Not authorized to update price");
        _;
    }
    
    constructor(uint256 _supportLevel, uint256 _resistanceLevel, uint256 _initialPrice, address _priceUpdater) {
        require(_supportLevel < _resistanceLevel, "Support must be less than resistance");
        owner = msg.sender;
        supportLevel = _supportLevel;
        resistanceLevel = _resistanceLevel;
        lastPrice = _initialPrice;
        priceUpdater = _priceUpdater;
    }

    /// @notice Allows the owner to update the support and resistance levels.
    /// @param _newSupport The new support level.
    /// @param _newResistance The new resistance level.
    function updateThresholds(uint256 _newSupport, uint256 _newResistance) external onlyOwner {
        require(_newSupport < _newResistance, "Support must be less than resistance");
        supportLevel = _newSupport;
        resistanceLevel = _newResistance;
    }

    /// @notice Updates the price and checks for a break event.
    /// Only the authorized priceUpdater can call this function.
    /// @param _newPrice The new price to update.
    function updatePrice(uint256 _newPrice) external onlyPriceUpdater {
        lastPrice = _newPrice;
        emit PriceUpdated(_newPrice);
        
        if (_newPrice > resistanceLevel) {
            emit UpwardBreak(_newPrice, resistanceLevel);
        } else if (_newPrice < supportLevel) {
            emit DownwardBreak(_newPrice, supportLevel);
        }
    }

    /// @notice Retrieves the current price and thresholds.
    /// @return currentPrice The last updated price.
    /// @return currentSupport The current support level.
    /// @return currentResistance The current resistance level.
    function getMarketInfo() external view returns (uint256 currentPrice, uint256 currentSupport, uint256 currentResistance) {
        currentPrice = lastPrice;
        currentSupport = supportLevel;
        currentResistance = resistanceLevel;
    }
}
