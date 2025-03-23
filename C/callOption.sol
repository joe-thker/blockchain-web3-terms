// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CallOption
/// @notice A simple call option contract that allows a seller to create an option
/// by depositing Ether as the underlying asset, and a buyer to purchase and exercise the option.
contract CallOption {
    address payable public seller;
    address public buyer;

    // Strike price and premium are in wei.
    uint256 public strikePrice;
    uint256 public premium;
    uint256 public expiry; // Unix timestamp when the option expires.
    uint256 public underlyingAsset; // Amount of Ether deposited as the underlying asset.

    enum OptionState { Created, Purchased, Exercised, Expired }
    OptionState public state;

    event OptionCreated(
        address indexed seller,
        uint256 strikePrice,
        uint256 premium,
        uint256 expiry,
        uint256 underlyingAsset
    );
    event OptionPurchased(address indexed buyer, uint256 premium);
    event OptionExercised(address indexed buyer, uint256 strikePrice);
    event OptionExpired(address indexed seller);

    /// @notice Seller creates an option by depositing Ether and specifying parameters.
    /// @param _strikePrice The price at which the buyer can purchase the asset (in wei).
    /// @param _premium The premium that the buyer must pay to purchase the option (in wei).
    /// @param _expiry The expiration timestamp of the option.
    function createOption(
        uint256 _strikePrice,
        uint256 _premium,
        uint256 _expiry
    ) external payable {
        require(msg.value > 0, "Underlying asset must be > 0");
        require(_expiry > block.timestamp, "Expiry must be in the future");
        seller = payable(msg.sender);
        strikePrice = _strikePrice;
        premium = _premium;
        expiry = _expiry;
        underlyingAsset = msg.value;
        state = OptionState.Created;
        emit OptionCreated(seller, strikePrice, premium, expiry, underlyingAsset);
    }

    /// @notice Buyer purchases the option by paying the exact premium.
    function buyOption() external payable {
        require(state == OptionState.Created, "Option not available for purchase");
        require(msg.value == premium, "Incorrect premium amount");
        buyer = msg.sender;
        state = OptionState.Purchased;
        emit OptionPurchased(buyer, premium);
    }

    /// @notice Buyer exercises the option by paying the strike price before expiry.
    function exerciseOption() external payable {
        require(state == OptionState.Purchased, "Option not in purchased state");
        require(block.timestamp < expiry, "Option has expired");
        require(msg.sender == buyer, "Only the buyer can exercise the option");
        require(msg.value == strikePrice, "Incorrect strike price amount");

        state = OptionState.Exercised;

        // Transfer the underlying asset to the buyer.
        (bool assetSent, ) = buyer.call{value: underlyingAsset}("");
        require(assetSent, "Transfer of underlying asset failed");

        // Transfer the strike price to the seller.
        (bool strikeSent, ) = seller.call{value: strikePrice}("");
        require(strikeSent, "Transfer of strike price failed");

        emit OptionExercised(buyer, strikePrice);
    }

    /// @notice After expiry, if the option is not exercised, seller can reclaim the underlying asset.
    function expireOption() external {
        require(block.timestamp >= expiry, "Option not yet expired");
        require(state == OptionState.Created || state == OptionState.Purchased, "Option already exercised or expired");
        state = OptionState.Expired;
        (bool refunded, ) = seller.call{value: underlyingAsset}("");
        require(refunded, "Refund of underlying asset failed");
        emit OptionExpired(seller);
    }
}
