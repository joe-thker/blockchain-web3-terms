// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * English Auction Marketplace
 * – Sellers create an auction with a reserve price and duration.
 * – Bidders outbid each other; previous highest bid is refunded.
 * – After time expires, anyone can settle: winner gets NFT, seller gets proceeds.
 */
contract EnglishAuctionMarketplace is ReentrancyGuard {
    struct Auction {
        address seller;
        address token;
        uint256 tokenId;
        uint256 reservePrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool settled;
    }

    uint256 public nextAuctionId = 1;
    mapping(uint256 => Auction) public auctions;

    event AuctionCreated(uint256 indexed id, address seller, address token, uint256 tokenId, uint256 reservePrice, uint256 duration);
    event BidPlaced(uint256 indexed id, address bidder, uint256 amount);
    event AuctionSettled(uint256 indexed id, address winner, uint256 amount);
    event AuctionCanceled(uint256 indexed id);

    function createAuction(
        address token,
        uint256 tokenId,
        uint256 reservePrice,
        uint256 duration
    ) external returns (uint256 id) {
        require(duration > 0, "duration>0");
        IERC721 nft = IERC721(token);
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner");
        require(
            nft.getApproved(tokenId) == address(this) ||
            nft.isApprovedForAll(msg.sender, address(this)),
            "Not approved"
        );

        id = nextAuctionId++;
        auctions[id] = Auction({
            seller: msg.sender,
            token: token,
            tokenId: tokenId,
            reservePrice: reservePrice,
            endTime: block.timestamp + duration,
            highestBidder: address(0),
            highestBid: 0,
            settled: false
        });

        emit AuctionCreated(id, msg.sender, token, tokenId, reservePrice, duration);
    }

    function bid(uint256 id) external payable nonReentrant {
        Auction storage a = auctions[id];
        require(block.timestamp < a.endTime, "ended");
        uint256 minBid = a.highestBid == 0 ? a.reservePrice : a.highestBid + 1 wei;
        require(msg.value >= minBid, "low bid");

        // refund previous
        if (a.highestBidder != address(0)) {
            payable(a.highestBidder).transfer(a.highestBid);
        }

        a.highestBidder = msg.sender;
        a.highestBid    = msg.value;
        emit BidPlaced(id, msg.sender, msg.value);
    }

    function cancelAuction(uint256 id) external nonReentrant {
        Auction storage a = auctions[id];
        require(msg.sender == a.seller, "not seller");
        require(a.highestBid == 0, "has bids");
        require(!a.settled, "settled");
        a.settled = true;
        emit AuctionCanceled(id);
    }

    function settle(uint256 id) external nonReentrant {
        Auction storage a = auctions[id];
        require(block.timestamp >= a.endTime, "not ended");
        require(!a.settled, "already settled");
        a.settled = true;

        if (a.highestBidder != address(0)) {
            // transfer NFT to winner
            IERC721(a.token).safeTransferFrom(a.seller, a.highestBidder, a.tokenId);
            // pay seller
            payable(a.seller).transfer(a.highestBid);
            emit AuctionSettled(id, a.highestBidder, a.highestBid);
        } else {
            // no bids: nothing to do
            emit AuctionSettled(id, address(0), 0);
        }
    }
}
