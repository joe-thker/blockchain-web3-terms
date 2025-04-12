// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAuction {
    function bid() external payable;
    function currentBid() external view returns (uint256);
    function auctionEndTime() external view returns (uint256);
}

contract AuctionSnipingBot {
    IAuction public auction;
    address public owner;

    constructor(address _auction) {
        auction = IAuction(_auction);
        owner = msg.sender;
    }

    function snipe() external payable {
        require(msg.sender == owner, "Not owner");
        require(block.timestamp + 10 >= auction.auctionEndTime(), "Too early");

        uint256 newBid = auction.currentBid() + 0.01 ether;
        require(msg.value >= newBid, "Not enough");

        auction.bid{value: msg.value}();
    }
}
