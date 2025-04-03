// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title EquityToken
/// @notice An ERC20 token representing equity with a dynamic offering mechanism.
/// Users can purchase equity tokens by sending ETH at the current token price (in wei).
/// The owner can update the token price and withdraw the raised funds.
contract EquityToken is ERC20, Ownable, ReentrancyGuard {
    /// @notice Price per token in wei (i.e., the cost for one token unit).
    uint256 public tokenPrice;
    /// @notice Total ETH raised from equity purchases.
    uint256 public totalRaised;

    /// @notice Emitted when the token price is updated.
    event TokenPriceUpdated(uint256 newPrice);
    /// @notice Emitted when a user purchases equity tokens.
    event EquityPurchased(address indexed buyer, uint256 tokensMinted, uint256 ethSpent);

    /**
     * @notice Constructor initializes the equity token with a name, symbol, and initial token price.
     * @param initialPrice The initial token price in wei.
     */
    constructor(uint256 initialPrice)
        ERC20("EquityToken", "EQT")
        Ownable(msg.sender)
    {
        require(initialPrice > 0, "Price must be > 0");
        tokenPrice = initialPrice;
    }

    /**
     * @notice Allows the owner to update the token price.
     * @param newPrice The new token price in wei.
     */
    function updateTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be > 0");
        tokenPrice = newPrice;
        emit TokenPriceUpdated(newPrice);
    }

    /**
     * @notice Allows users to purchase equity tokens by sending ETH.
     * The number of tokens minted is equal to (msg.value / tokenPrice), with any remainder refunded.
     */
    function purchaseEquity() public payable nonReentrant {
        require(msg.value >= tokenPrice, "Not enough ETH sent");
        // Calculate the number of tokens to mint.
        uint256 tokensToMint = msg.value / tokenPrice;
        uint256 ethUsed = tokensToMint * tokenPrice;
        uint256 refund = msg.value - ethUsed;
        
        totalRaised += ethUsed;
        // Mint tokens scaled by decimals (ERC20 default is 18 decimals).
        _mint(msg.sender, tokensToMint * (10 ** decimals()));
        
        // Refund any excess ETH.
        if (refund > 0) {
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund failed");
        }
        
        emit EquityPurchased(msg.sender, tokensToMint, ethUsed);
    }

    /**
     * @notice Fallback function that calls purchaseEquity when ETH is sent directly.
     */
    receive() external payable {
        purchaseEquity();
    }

    /**
     * @notice Allows the owner to withdraw the ETH raised from the offering.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawFunds(uint256 amount) external onlyOwner nonReentrant {
        require(amount <= address(this).balance, "Insufficient ETH balance");
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdrawal failed");
    }
}
