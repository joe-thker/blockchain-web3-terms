// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VolatilityOracle - Tracks volatility using price variance
contract VolatilityOracle {
    address public immutable admin;
    uint256 public lastPrice;
    uint256 public lastUpdated;
    uint256 public ewmaVolatility; // Scaled by 1e18

    uint256 public constant ALPHA = 0.2e18; // EWMA weighting factor

    event VolatilityUpdated(uint256 price, uint256 newVolatility);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(uint256 initialPrice) {
        admin = msg.sender;
        lastPrice = initialPrice;
        lastUpdated = block.timestamp;
        ewmaVolatility = 0;
    }

    /// @notice Called periodically with new price (e.g., every 10 min)
    function updatePrice(uint256 newPrice) external onlyAdmin {
        require(newPrice > 0, "Invalid price");

        uint256 delta = newPrice > lastPrice ? newPrice - lastPrice : lastPrice - newPrice;
        uint256 pctChange = (delta * 1e18) / lastPrice;

        // EWMA: volatility = α * new + (1-α) * old
        ewmaVolatility = (ALPHA * pctChange + (1e18 - ALPHA) * ewmaVolatility) / 1e18;

        lastPrice = newPrice;
        lastUpdated = block.timestamp;

        emit VolatilityUpdated(newPrice, ewmaVolatility);
    }

    function getVolatility() external view returns (uint256) {
        return ewmaVolatility;
    }
}
