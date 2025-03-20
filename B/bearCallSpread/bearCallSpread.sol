// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BearCallSpread
/// @notice A simplified simulation of a bear call spread options strategy.
/// @dev This contract sets up a spread with a lower strike, a higher strike, and a received premium.
///      It provides a settlement function to calculate the payoff based on a given settlement price of the underlying asset.
contract BearCallSpread {
    uint256 public lowerStrike;   // The lower strike price (sold call)
    uint256 public higherStrike;  // The higher strike price (bought call)
    uint256 public premium;       // Net premium received (could be used to offset loss)
    address public seller;        // Address of the seller of the spread
    bool public settled;          // Indicates whether the spread has been settled
    uint256 public settlementPrice; // The underlying asset's price at settlement

    // Event emitted when the spread is settled
    event SpreadSettled(uint256 settlementPrice, uint256 payout);

    /// @notice Constructor to initialize the bear call spread.
    /// @param _lowerStrike The lower strike price (sold call).
    /// @param _higherStrike The higher strike price (bought call). Must be greater than _lowerStrike.
    /// @param _premium The net premium received (in wei).
    constructor(uint256 _lowerStrike, uint256 _higherStrike, uint256 _premium) payable {
        require(_lowerStrike < _higherStrike, "Lower strike must be less than higher strike");
        lowerStrike = _lowerStrike;
        higherStrike = _higherStrike;
        premium = _premium;
        seller = msg.sender;
        settled = false;
    }

    /// @notice Settles the spread using the settlement price of the underlying asset.
    /// @param _settlementPrice The settlement price of the underlying asset.
    /// @dev The payoff calculation is as follows:
    ///      - If the settlement price <= lowerStrike, no payout is required.
    ///      - If settlement price is between lowerStrike and higherStrike, payout = settlementPrice - lowerStrike.
    ///      - If settlement price >= higherStrike, payout is capped at (higherStrike - lowerStrike).
    function settle(uint256 _settlementPrice) public {
        require(!settled, "Spread already settled");
        settlementPrice = _settlementPrice;
        settled = true;
        uint256 payout;

        if (_settlementPrice <= lowerStrike) {
            payout = 0;
        } else if (_settlementPrice < higherStrike) {
            payout = _settlementPrice - lowerStrike;
        } else {
            payout = higherStrike - lowerStrike;
        }

        // In a full implementation, the premium received would be deducted from the loss or added to the profit.
        emit SpreadSettled(_settlementPrice, payout);
    }
}
