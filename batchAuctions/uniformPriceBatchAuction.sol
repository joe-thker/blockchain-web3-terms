// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UniformPriceBatchAuction {
    struct Bid {
        address bidder;
        uint256 price; // bid price (in wei) per unit
    }

    Bid[] public bids;
    bool public auctionClosed;
    uint256 public clearingPrice;
    uint256 public supply; // number of units available for sale
    address public admin;
    mapping(address => bool) public isWinner;

    event BidPlaced(address indexed bidder, uint256 price);
    event AuctionClosed(uint256 clearingPrice, address[] winners);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(uint256 _supply) {
        admin = msg.sender;
        supply = _supply;
        auctionClosed = false;
    }

    // Bidders call this function to submit their bid (bid price)
    function bid(uint256 price) public {
        require(!auctionClosed, "Auction closed");
        bids.push(Bid({bidder: msg.sender, price: price}));
        emit BidPlaced(msg.sender, price);
    }

    // Simple bubble sort to sort bids in descending order by price
    function sortBids() internal {
        uint256 n = bids.length;
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = 0; j < n - 1; j++) {
                if (bids[j].price < bids[j+1].price) {
                    Bid memory temp = bids[j];
                    bids[j] = bids[j+1];
                    bids[j+1] = temp;
                }
            }
        }
    }

    // Admin closes the auction and determines the uniform clearing price
    function closeAuction() public onlyAdmin {
        require(!auctionClosed, "Auction already closed");
        require(bids.length >= supply, "Not enough bids");
        sortBids();
        // The clearing price is the price of the last winning bid.
        clearingPrice = bids[supply - 1].price;

        // Mark the top 'supply' bidders as winners.
        for (uint256 i = 0; i < supply; i++) {
            isWinner[bids[i].bidder] = true;
        }

        auctionClosed = true;

        // Build winners array for the event.
        address[] memory winnersList = new address[](supply);
        for (uint256 i = 0; i < supply; i++) {
            winnersList[i] = bids[i].bidder;
        }
        emit AuctionClosed(clearingPrice, winnersList);
    }
}
