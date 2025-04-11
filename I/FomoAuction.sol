// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FomoAuction {
    address public highestBidder;
    uint256 public highestBid;
    uint256 public endTime;
    uint256 public extension = 2 minutes;

    constructor() {
        endTime = block.timestamp + 10 minutes;
    }

    function bid() external payable {
        require(block.timestamp < endTime, "Ended");
        require(msg.value > highestBid, "Bid too low");

        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }

        highestBid = msg.value;
        highestBidder = msg.sender;
        endTime = block.timestamp + extension;
    }

    function claim() external {
        require(block.timestamp >= endTime, "Auction live");
        require(msg.sender == highestBidder, "Not winner");
        payable(msg.sender).transfer(address(this).balance);
    }
}
