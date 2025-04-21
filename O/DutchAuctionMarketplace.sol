// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * Dutch Auction Marketplace
 * – Seller sets startPrice → endPrice over a duration.
 * – Price linearly falls; buyer calls `buy` and pays current price.
 */
contract DutchAuctionMarketplace is ReentrancyGuard {
    struct Auction {
        address seller;
        address token;
        uint256 tokenId;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 endTime;
        bool    sold;
    }

    uint256 public nextAuctionId = 1;
    mapping(uint256 => Auction) public auctions;

    event DutchAuctionCreated(uint256 indexed id, address seller, address token, uint256 tokenId, uint256 startPrice, uint256 endPrice, uint256 duration);
    event DutchAuctionSold(uint256 indexed id, address buyer, uint256 price);
    event DutchAuctionCanceled(uint256 indexed id);

    function createDutchAuction(
        address token,
        uint256 tokenId,
        uint256 startPrice,
        uint256 endPrice,
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
        require(startPrice > endPrice, "start> end");

        id = nextAuctionId++;
        auctions[id] = Auction({
            seller: msg.sender,
            token: token,
            tokenId: tokenId,
            startPrice: startPrice,
            endPrice: endPrice,
            startTime: block.timestamp,
            endTime:   block.timestamp + duration,
            sold: false
        });
        emit DutchAuctionCreated(id, msg.sender, token, tokenId, startPrice, endPrice, duration);
    }

    function getCurrentPrice(uint256 id) public view returns (uint256) {
        Auction storage a = auctions[id];
        if (block.timestamp >= a.endTime) return a.endPrice;
        uint256 elapsed = block.timestamp - a.startTime;
        uint256 span    = a.endTime - a.startTime;
        // linear interpolation
        return a.startPrice - ( (a.startPrice - a.endPrice) * elapsed ) / span;
    }

    function buy(uint256 id) external payable nonReentrant {
        Auction storage a = auctions[id];
        require(!a.sold, "sold");
        uint256 price = getCurrentPrice(id);
        require(msg.value >= price, "low ETH");
        a.sold = true;

        // transfer NFT, pay seller, refund excess
        IERC721(a.token).safeTransferFrom(a.seller, msg.sender, a.tokenId);
        payable(a.seller).transfer(price);
        if (msg.value > price) payable(msg.sender).transfer(msg.value - price);

        emit DutchAuctionSold(id, msg.sender, price);
    }

    function cancelDutchAuction(uint256 id) external nonReentrant {
        Auction storage a = auctions[id];
        require(msg.sender == a.seller, "not seller");
        require(!a.sold, "sold");
        a.sold = true;
        emit DutchAuctionCanceled(id);
    }
}
