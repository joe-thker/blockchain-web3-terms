// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BuyWall
/// @notice This contract simulates a "buy wall" mechanism by holding funds that are used to purchase tokens
/// automatically when the current market price falls to or below a specified threshold.
contract BuyWall {
    address public owner;
    uint256 public buyWallPrice;  // The price threshold (in wei) at which the buy wall is triggered.
    uint256 public currentPrice;  // The current market price (in wei).
    uint256 public totalFunds;    // Total funds deposited for executing the buy wall.

    event FundsDeposited(address indexed depositor, uint256 amount);
    event PriceUpdated(uint256 newPrice);
    event BuyWallPriceUpdated(uint256 newBuyWallPrice);
    event BuyWallExecuted(address indexed executor, uint256 tokensBought, uint256 purchasePrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the owner, initial buy wall price, and current price.
    /// @param _buyWallPrice The initial buy wall price.
    /// @param _initialPrice The initial market price.
    constructor(uint256 _buyWallPrice, uint256 _initialPrice) {
        owner = msg.sender;
        buyWallPrice = _buyWallPrice;
        currentPrice = _initialPrice;
        totalFunds = 0;
    }

    /// @notice Deposits funds into the contract for executing the buy wall.
    function depositFunds() external payable {
        require(msg.value > 0, "Must deposit some Ether");
        totalFunds += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows the owner to update the current market price.
    /// @param _newPrice The new market price.
    function updatePrice(uint256 _newPrice) external onlyOwner {
        currentPrice = _newPrice;
        emit PriceUpdated(_newPrice);
    }

    /// @notice Allows the owner to update the buy wall price.
    /// @param _newBuyWallPrice The new buy wall price.
    function updateBuyWallPrice(uint256 _newBuyWallPrice) external onlyOwner {
        buyWallPrice = _newBuyWallPrice;
        emit BuyWallPriceUpdated(_newBuyWallPrice);
    }

    /// @notice Executes the buy wall if the current market price is at or below the buy wall price.
    /// It calculates how many tokens can be bought with the available funds.
    /// @return tokensBought The number of tokens that could be purchased.
    function executeBuyWall() external returns (uint256 tokensBought) {
        require(currentPrice <= buyWallPrice, "Current price is above the buy wall price");
        require(totalFunds > 0, "No funds available for buying");

        // Calculate tokens bought: tokensBought = totalFunds / currentPrice.
        tokensBought = totalFunds / currentPrice;
        // Reset total funds to zero after executing the buy wall.
        totalFunds = 0;
        emit BuyWallExecuted(msg.sender, tokensBought, currentPrice);
    }
}
