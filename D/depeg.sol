// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DepegMonitor
/// @notice Monitors the price of a stablecoin and detects when it depegs (i.e., goes beyond a certain threshold from its peg price).
/// The owner can dynamically update the peg price, threshold, and the authorized aggregator that reports prices.
contract DepegMonitor is Ownable, ReentrancyGuard {
    /// @notice The stablecoin’s ideal peg price in scaled integer form (e.g. 1.0 USD = 1e8).
    uint256 public pegPrice;
    /// @notice Deviation threshold in basis points. For instance, 500 = 5%.
    uint256 public thresholdBps;
    /// @notice The last reported price of the stablecoin (scaled integer, e.g., 1.05 USD = 105000000).
    uint256 public lastPrice;
    /// @notice Address authorized to update the stablecoin price (e.g., an oracle or aggregator).
    address public priceAggregator;
    /// @notice Whether the stablecoin is currently considered depegged.
    bool public isDepegged;

    // --- Events ---
    event AggregatorUpdated(address indexed newAggregator);
    event ThresholdUpdated(uint256 newThresholdBps);
    event PegPriceUpdated(uint256 newPegPrice);
    event PriceReported(uint256 reportedPrice, bool depegged);
    event Depegged(uint256 timestamp, uint256 price);
    event Repegged(uint256 timestamp, uint256 price);

    /// @notice Constructor sets the initial peg price, threshold, aggregator, and owner.
    /// @param _pegPrice The stablecoin’s ideal peg price (in scaled integer form).
    /// @param _thresholdBps The basis-point deviation threshold (e.g., 500 for 5%).
    /// @param _priceAggregator The address authorized to update the price.
    constructor(uint256 _pegPrice, uint256 _thresholdBps, address _priceAggregator)
        Ownable(msg.sender)
    {
        require(_pegPrice > 0, "Peg price must be > 0");
        require(_thresholdBps <= 2000, "Threshold too high (max 20%)");
        require(_priceAggregator != address(0), "Invalid aggregator address");

        pegPrice = _pegPrice;
        thresholdBps = _thresholdBps;
        priceAggregator = _priceAggregator;
        isDepegged = false;
    }

    /// @notice Updates the aggregator address allowed to report stablecoin prices.
    /// Only callable by the owner.
    /// @param newAggregator The new aggregator address.
    function updateAggregator(address newAggregator) external onlyOwner {
        require(newAggregator != address(0), "Invalid aggregator address");
        priceAggregator = newAggregator;
        emit AggregatorUpdated(newAggregator);
    }

    /// @notice Updates the deviation threshold in basis points. Only callable by the owner.
    /// e.g., 500 means 5%.
    /// @param newThresholdBps The new threshold in basis points.
    function updateThreshold(uint256 newThresholdBps) external onlyOwner {
        require(newThresholdBps <= 2000, "Threshold too high (max 20%)");
        thresholdBps = newThresholdBps;
        emit ThresholdUpdated(newThresholdBps);
    }

    /// @notice Updates the stablecoin’s ideal peg price. Only callable by the owner.
    /// e.g., 1.00 USD = 1e8 if using 8 decimal scaling.
    /// @param newPegPrice The new peg price in scaled integer form.
    function updatePegPrice(uint256 newPegPrice) external onlyOwner {
        require(newPegPrice > 0, "Peg price must be > 0");
        pegPrice = newPegPrice;
        emit PegPriceUpdated(newPegPrice);
    }

    /// @notice The aggregator reports the stablecoin’s current price.
    /// This function checks if the stablecoin is depegged based on the threshold from pegPrice.
    /// @param reportedPrice The stablecoin’s reported price (in scaled integer form).
    function reportPrice(uint256 reportedPrice) external nonReentrant {
        require(msg.sender == priceAggregator, "Not authorized aggregator");
        require(reportedPrice > 0, "Invalid reported price");

        lastPrice = reportedPrice;
        bool currentlyDepegged = _checkDepeg(reportedPrice);

        emit PriceReported(reportedPrice, currentlyDepegged);

        if (currentlyDepegged && !isDepegged) {
            // Transition from pegged -> depegged
            isDepegged = true;
            emit Depegged(block.timestamp, reportedPrice);
        } else if (!currentlyDepegged && isDepegged) {
            // Transition from depegged -> pegged
            isDepegged = false;
            emit Repegged(block.timestamp, reportedPrice);
        }
    }

    /// @notice Internal helper that checks if the stablecoin’s current price has depegged.
    /// @param price The stablecoin’s reported price.
    /// @return True if the price is outside the threshold from pegPrice, false otherwise.
    function _checkDepeg(uint256 price) internal view returns (bool) {
        // Calculate absolute difference from pegPrice
        uint256 diff = (price > pegPrice) ? price - pegPrice : pegPrice - price;
        // If diff * 10000 / pegPrice > thresholdBps => depegged
        // Multiply first to avoid rounding issues
        uint256 diffBps = (diff * 10000) / pegPrice;
        return diffBps > thresholdBps;
    }
}
