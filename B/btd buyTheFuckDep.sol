// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BuyTheFuckDip
/// @notice A contract that simulates a dip-buying mechanism in crypto markets.
/// When the current price falls below a preset dip threshold, users can buy tokens at that dip.
contract BuyTheFuckDip {
    address public owner;
    uint256 public dipThreshold; // Price threshold below which it is considered a "dip"
    uint256 public currentPrice; // Current market price (in wei or chosen unit)
    
    // Mapping to track the number of tokens purchased by each buyer.
    mapping(address => uint256) public tokensPurchased;
    
    // Events to log price updates, threshold changes, and dip purchase actions.
    event PriceUpdated(uint256 newPrice);
    event DipThresholdUpdated(uint256 newThreshold);
    event DipBought(address indexed buyer, uint256 tokensBought, uint256 purchasePrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /// @notice Constructor sets the owner, initial dip threshold, and initial price.
    /// @param _dipThreshold The price threshold that defines a dip.
    /// @param _initialPrice The initial market price.
    constructor(uint256 _dipThreshold, uint256 _initialPrice) {
        owner = msg.sender;
        dipThreshold = _dipThreshold;
        currentPrice = _initialPrice;
    }
    
    /// @notice Allows the owner to update the current market price.
    /// @param _newPrice The new market price.
    function updatePrice(uint256 _newPrice) external onlyOwner {
        currentPrice = _newPrice;
        emit PriceUpdated(_newPrice);
    }
    
    /// @notice Allows the owner to update the dip threshold.
    /// @param _newThreshold The new dip threshold.
    function updateDipThreshold(uint256 _newThreshold) external onlyOwner {
        dipThreshold = _newThreshold;
        emit DipThresholdUpdated(_newThreshold);
    }
    
    /// @notice Allows users to buy tokens when the current price is below the dip threshold.
    /// Tokens are calculated as the amount of Ether sent divided by the current price.
    function buyDip() external payable {
        require(currentPrice < dipThreshold, "Price is not low enough to buy the dip");
        require(msg.value > 0, "Must send Ether to buy tokens");
        
        uint256 tokensBought = msg.value / currentPrice;
        require(tokensBought > 0, "Not enough Ether to buy even one token");
        
        tokensPurchased[msg.sender] += tokensBought;
        emit DipBought(msg.sender, tokensBought, currentPrice);
    }
}
