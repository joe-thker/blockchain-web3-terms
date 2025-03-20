// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimal ERC20 interface
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title BearHugOffer
/// @notice A contract that simulates a bear hug offer for an ERC20 token.
/// The offeror funds the contract with Ether and sets an offer price per token and an expiry time.
/// Token holders can accept the offer to sell their tokens at the given price before the offer expires.
contract BearHugOffer {
    address public owner;          // The offeror
    IERC20 public token;           // The ERC20 token being acquired
    uint256 public offerPrice;     // Offer price in wei per token
    uint256 public expiry;         // Unix timestamp when the offer expires

    event OfferAccepted(address indexed seller, uint256 tokenAmount, uint256 payout);
    event OfferFunded(address indexed owner, uint256 amount);

    modifier onlyBeforeExpiry() {
        require(block.timestamp <= expiry, "Offer expired");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice Constructor to initialize the bear hug offer.
    /// @param _tokenAddress The address of the ERC20 token.
    /// @param _offerPrice The offer price in wei per token.
    /// @param _expiry The Unix timestamp when the offer expires.
    /// @dev The contract should be deployed with sufficient Ether to cover expected payouts.
    constructor(address _tokenAddress, uint256 _offerPrice, uint256 _expiry) payable {
        require(_expiry > block.timestamp, "Expiry must be in the future");
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        offerPrice = _offerPrice;
        expiry = _expiry;
    }

    /// @notice Allows the owner to fund additional Ether into the contract.
    function fundOffer() external payable onlyOwner {
        require(msg.value > 0, "Must send Ether");
        emit OfferFunded(msg.sender, msg.value);
    }

    /// @notice Allows token holders to accept the bear hug offer.
    /// @param tokenAmount The number of tokens to sell.
    /// @dev Token holders must approve this contract to spend their tokens beforehand.
    function acceptOffer(uint256 tokenAmount) external onlyBeforeExpiry {
        uint256 payout = tokenAmount * offerPrice;
        require(address(this).balance >= payout, "Insufficient funds in offer contract");

        // Transfer tokens from the seller to the owner (offeror).
        bool success = token.transferFrom(msg.sender, owner, tokenAmount);
        require(success, "Token transfer failed");

        // Send Ether payout to the seller.
        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "Failed to send Ether");

        emit OfferAccepted(msg.sender, tokenAmount, payout);
    }

    /// @notice Allows the owner to withdraw remaining funds after the offer expires.
    function withdrawFunds() external onlyOwner {
        require(block.timestamp > expiry, "Offer not expired");
        uint256 balance = address(this).balance;
        (bool sent, ) = owner.call{value: balance}("");
        require(sent, "Withdrawal failed");
    }
}
