// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ClosingPrice
/// @notice This contract stores the closing price of an asset.
/// Only the owner can update the closing price.
contract ClosingPrice {
    address public owner;
    uint256 public closingPrice;
    uint256 public lastUpdated;

    event ClosingPriceUpdated(uint256 newPrice, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor initializes the contract with an initial closing price.
    /// @param initialPrice The starting closing price.
    constructor(uint256 initialPrice) {
        owner = msg.sender;
        closingPrice = initialPrice;
        lastUpdated = block.timestamp;
    }

    /// @notice Updates the closing price.
    /// @param newPrice The new closing price.
    function updateClosingPrice(uint256 newPrice) external onlyOwner {
        closingPrice = newPrice;
        lastUpdated = block.timestamp;
        emit ClosingPriceUpdated(newPrice, lastUpdated);
    }

    /// @notice Retrieves the current closing price along with the last update timestamp.
    /// @return price The closing price.
    /// @return timestamp The timestamp when the price was last updated.
    function getClosingPrice() external view returns (uint256 price, uint256 timestamp) {
        return (closingPrice, lastUpdated);
    }
}
