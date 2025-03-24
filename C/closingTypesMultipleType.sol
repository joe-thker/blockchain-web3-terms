// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MultiClosingPrice
/// @notice This contract tracks closing prices for different periods: Daily, Weekly, and Monthly.
/// Only the owner can update the closing prices.
contract MultiClosingPrice {
    address public owner;

    // Different types of closing prices.
    enum PriceType { Daily, Weekly, Monthly }
    
    // Record structure to hold a closing price and the timestamp when it was updated.
    struct PriceRecord {
        uint256 price;
        uint256 timestamp;
    }
    
    // Mapping from PriceType (cast as uint) to a PriceRecord.
    mapping(uint256 => PriceRecord) public closingPrices;

    event ClosingPriceUpdated(PriceType priceType, uint256 newPrice, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Updates the closing price for a specific type (Daily, Weekly, or Monthly).
    /// @param priceType The type of closing price (0 = Daily, 1 = Weekly, 2 = Monthly).
    /// @param newPrice The new closing price.
    function updateClosingPrice(PriceType priceType, uint256 newPrice) external onlyOwner {
        closingPrices[uint256(priceType)] = PriceRecord(newPrice, block.timestamp);
        emit ClosingPriceUpdated(priceType, newPrice, block.timestamp);
    }

    /// @notice Retrieves the closing price for a specific type.
    /// @param priceType The type of closing price to retrieve.
    /// @return price The closing price.
    /// @return timestamp The timestamp when the price was last updated.
    function getClosingPrice(PriceType priceType) external view returns (uint256 price, uint256 timestamp) {
        PriceRecord memory record = closingPrices[uint256(priceType)];
        return (record.price, record.timestamp);
    }
}
