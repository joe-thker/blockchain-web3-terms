// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BidPriceAuction
/// @notice A simple bidding contract where the highest bid represents the bid price.
contract BidPriceAuction {
    address public highestBidder;
    uint256 public highestBid;

    // Event emitted when a new highest bid is placed.
    event NewHighestBid(address indexed bidder, uint256 bid);

    /// @notice Allows users to place a bid. The bid must be higher than the current highest bid.
    function placeBid() external payable {
        require(msg.value > highestBid, "Bid must be higher than current highest bid");
        
        // Update the highest bid and bidder.
        highestBid = msg.value;
        highestBidder = msg.sender;

        emit NewHighestBid(msg.sender, msg.value);
    }

    /// @notice Returns the current bid price (highest bid).
    /// @return The highest bid value in wei.
    function getBidPrice() external view returns (uint256) {
        return highestBid;
    }
}
