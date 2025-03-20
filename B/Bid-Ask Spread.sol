// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BidAskSpread
/// @notice A simple contract to simulate a bid-ask spread mechanism.
contract BidAskSpread {
    // Highest bid (in wei)
    uint256 public highestBid;
    // Lowest ask (in wei). Initialized to the maximum uint256 value.
    uint256 public lowestAsk;

    // Events to log bid placements, ask placements, and spread calculation.
    event BidPlaced(address indexed bidder, uint256 bid);
    event AskPlaced(address indexed asker, uint256 ask);
    event SpreadCalculated(uint256 spread);

    /// @notice Constructor initializes the highest bid to 0 and lowest ask to max value.
    constructor() {
        highestBid = 0;
        lowestAsk = type(uint256).max;
    }

    /// @notice Allows a user to place a bid. The bid must be higher than the current highest bid.
    function placeBid() external payable {
        require(msg.value > highestBid, "Bid must be higher than current highest bid");
        highestBid = msg.value;
        emit BidPlaced(msg.sender, msg.value);
    }

    /// @notice Allows a seller to set an ask price. The ask price must be lower than the current lowest ask.
    /// @param askPrice The new ask price in wei.
    function placeAsk(uint256 askPrice) external {
        require(askPrice < lowestAsk, "Ask must be lower than current lowest ask");
        lowestAsk = askPrice;
        emit AskPlaced(msg.sender, askPrice);
    }

    /// @notice Returns the current bid-ask spread.
    /// @return spread The bid-ask spread in wei (lowestAsk - highestBid), or 0 if not available.
    function getSpread() external view returns (uint256 spread) {
        // If no ask has been set or no bid is placed, return 0.
        if (lowestAsk == type(uint256).max || highestBid == 0) {
            return 0;
        }
        // In a well-formed order book, lowestAsk should be greater than or equal to highestBid.
        require(lowestAsk >= highestBid, "Lowest ask is lower than highest bid");
        spread = lowestAsk - highestBid;
    }
}
