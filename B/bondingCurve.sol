// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BondingCurve
/// @notice A simple linear bonding curve contract for token issuance.
/// The token price increases linearly as more tokens are minted.
contract BondingCurve {
    // Initial price (in wei) for the first token.
    uint256 public initialPrice;
    // Slope of the bonding curve (additional price in wei per token minted).
    uint256 public slope;
    // Total number of tokens minted.
    uint256 public totalSupply;
    // Mapping to track each address's token balance.
    mapping(address => uint256) public balanceOf;

    // Event emitted when a token is purchased.
    event TokenPurchased(address indexed buyer, uint256 tokenId, uint256 price);

    /// @notice Constructor to set the initial price and slope.
    /// @param _initialPrice The price of the first token in wei.
    /// @param _slope The incremental price increase per token minted in wei.
    constructor(uint256 _initialPrice, uint256 _slope) {
        initialPrice = _initialPrice;
        slope = _slope;
        totalSupply = 0;
    }

    /// @notice Returns the current price for the next token.
    /// @return price The current token price in wei.
    function getCurrentPrice() public view returns (uint256 price) {
        price = initialPrice + (slope * totalSupply);
    }

    /// @notice Allows a user to buy one token at the current price.
    /// Excess Ether sent is refunded.
    function buyOneToken() external payable {
        uint256 price = getCurrentPrice();
        require(msg.value >= price, "Insufficient payment");

        totalSupply += 1;
        balanceOf[msg.sender] += 1;
        emit TokenPurchased(msg.sender, totalSupply, price);

        // Refund any excess payment.
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
}
