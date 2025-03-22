// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CryptoBubble
/// @notice This contract simulates a crypto market bubble by allowing investors to contribute Ether,
/// which increases the token price linearly. The owner can trigger a bubble burst to stop further investments.
contract CryptoBubble {
    address public owner;
    bool public bubbleBurst;
    uint256 public totalInvested;
    
    // Base price (in wei) for the token
    uint256 public initialPrice;
    // Price factor: the token price increases linearly with total invested funds.
    uint256 public priceFactor;
    
    // Mapping to track each investor's total contribution.
    mapping(address => uint256) public contributions;
    
    // Events to log investments and bubble burst.
    event Investment(address indexed investor, uint256 amount, uint256 newTotalInvested);
    event BubbleBurst(uint256 totalInvested);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier whenActive() {
        require(!bubbleBurst, "Bubble has burst");
        _;
    }
    
    /// @notice Constructor sets the initial parameters for the bubble.
    /// @param _initialPrice The starting price for tokens (in wei).
    /// @param _priceFactor The incremental price increase per wei invested.
    constructor(uint256 _initialPrice, uint256 _priceFactor) {
        owner = msg.sender;
        initialPrice = _initialPrice;
        priceFactor = _priceFactor;
        bubbleBurst = false;
        totalInvested = 0;
    }
    
    /// @notice Allows investors to contribute Ether to the bubble while it is active.
    function invest() external payable whenActive {
        require(msg.value > 0, "Investment must be > 0");
        contributions[msg.sender] += msg.value;
        totalInvested += msg.value;
        emit Investment(msg.sender, msg.value, totalInvested);
    }
    
    /// @notice Returns the current token price based on the linear bonding curve.
    /// @return The current price = initialPrice + (priceFactor * totalInvested).
    function currentPrice() public view returns (uint256) {
        return initialPrice + (priceFactor * totalInvested);
    }
    
    /// @notice Allows the owner to trigger the bubble burst, halting further investments.
    function burstBubble() external onlyOwner whenActive {
        bubbleBurst = true;
        emit BubbleBurst(totalInvested);
    }
}
