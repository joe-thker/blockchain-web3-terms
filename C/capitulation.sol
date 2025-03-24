// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CapitulationIndicator
/// @notice This contract tracks price updates and emits an event if the price falls below a set capitulation threshold.
/// The threshold is defined as a percentage drop from a reference price.
contract CapitulationIndicator {
    address public owner;
    uint256 public referencePrice;         // The initial or reference price to compare against.
    uint256 public capitulationThreshold;    // The percentage drop that signals capitulation (e.g., 50 means a 50% drop).
    uint256 public currentPrice;             // The latest updated price.

    event PriceUpdated(uint256 newPrice);
    event CapitulationDetected(uint256 currentPrice, uint256 referencePrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the owner, reference price, and capitulation threshold.
    /// @param _referencePrice The starting reference price.
    /// @param _capitulationThreshold The percentage drop to trigger capitulation.
    constructor(uint256 _referencePrice, uint256 _capitulationThreshold) {
        owner = msg.sender;
        referencePrice = _referencePrice;
        capitulationThreshold = _capitulationThreshold;
        currentPrice = _referencePrice;
    }

    /// @notice Updates the current price and checks if it falls below the capitulation threshold.
    /// @param _newPrice The new market price.
    function updatePrice(uint256 _newPrice) external onlyOwner {
        currentPrice = _newPrice;
        emit PriceUpdated(_newPrice);

        // Calculate the threshold price.
        // For example, if referencePrice = 1000 and threshold = 50, then thresholdPrice = 1000 * (100 - 50) / 100 = 500.
        uint256 thresholdPrice = (referencePrice * (100 - capitulationThreshold)) / 100;
        if (_newPrice <= thresholdPrice) {
            emit CapitulationDetected(_newPrice, referencePrice);
        }
    }

    /// @notice Updates the reference price.
    /// @param _newReferencePrice The new reference price.
    function updateReferencePrice(uint256 _newReferencePrice) external onlyOwner {
        referencePrice = _newReferencePrice;
    }

    /// @notice Updates the capitulation threshold.
    /// @param _newThreshold The new capitulation threshold percentage.
    function updateCapitulationThreshold(uint256 _newThreshold) external onlyOwner {
        capitulationThreshold = _newThreshold;
    }

    /// @notice Retrieves the current market info.
    /// @return refPrice The reference price.
    /// @return capThreshold The capitulation threshold percentage.
    /// @return currPrice The current price.
    function getMarketInfo() external view returns (uint256 refPrice, uint256 capThreshold, uint256 currPrice) {
        return (referencePrice, capitulationThreshold, currentPrice);
    }
}
