// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NiftyGatewayMarketplace
/// @notice A marketplace for listing and buying NFTs with a platform fee.
/// Only the owner (platform) can update settings, and NFT sellers can list their NFTs for sale.
contract NiftyGatewayMarketplace is Ownable {
    // Platform fee in basis points (e.g., 250 = 2.5%)
    uint256 public platformFeeBasisPoints = 250;

    struct Listing {
        address seller;
        uint256 price;
    }

    // Mapping from NFT contract address to tokenId to Listing details.
    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(address indexed nftAddress, uint256 indexed tokenId, uint256 salePrice, address seller);
    event NFTUnlisted(address indexed nftAddress, uint256 indexed tokenId);
    event NFTSold(address indexed nftAddress, uint256 indexed tokenId, uint256 salePrice, address buyer);

    /// @notice Constructor passes the initial owner to Ownable.
    /// @param initialOwner The address that will be set as the owner of the contract.
    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice List an NFT for sale.
    /// @param nftAddress The address of the NFT contract.
    /// @param tokenId The token ID of the NFT.
    /// @param salePrice The sale price in wei.
    function listNFT(address nftAddress, uint256 tokenId, uint256 salePrice) external {
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the NFT owner");
        require(salePrice > 0, "Sale price must be > 0");

        listings[nftAddress][tokenId] = Listing(msg.sender, salePrice);
        emit NFTListed(nftAddress, tokenId, salePrice, msg.sender);
    }

    /// @notice Cancel an NFT sale listing.
    /// @param nftAddress The address of the NFT contract.
    /// @param tokenId The token ID of the NFT.
    function unlistNFT(address nftAddress, uint256 tokenId) external {
        Listing memory listItem = listings[nftAddress][tokenId];
        require(listItem.seller == msg.sender, "Not the NFT seller");

        delete listings[nftAddress][tokenId];
        emit NFTUnlisted(nftAddress, tokenId);
    }

    /// @notice Buy a listed NFT.
    /// The buyer sends ETH equal or greater than the sale price.
    /// The sale amount is split between the seller (minus fee) and the platform.
    /// Any extra ETH is refunded.
    /// @param nftAddress The address of the NFT contract.
    /// @param tokenId The token ID of the NFT.
    function buyNFT(address nftAddress, uint256 tokenId) external payable {
        Listing memory listItem = listings[nftAddress][tokenId];
        require(listItem.price > 0, "NFT not listed for sale");
        require(msg.value >= listItem.price, "Insufficient funds");
        address seller = listItem.seller;
        require(seller != msg.sender, "Seller cannot be buyer");

        // Calculate platform fee.
        uint256 fee = (listItem.price * platformFeeBasisPoints) / 10000;
        uint256 sellerProceeds = listItem.price - fee;

        // Transfer NFT from seller to buyer.
        IERC721(nftAddress).transferFrom(seller, msg.sender, tokenId);

        // Transfer ETH: seller gets proceeds, owner gets fee.
        payable(seller).transfer(sellerProceeds);
        payable(owner()).transfer(fee);

        // Refund any excess ETH sent by buyer.
        if (msg.value > listItem.price) {
            payable(msg.sender).transfer(msg.value - listItem.price);
        }
        delete listings[nftAddress][tokenId];
        emit NFTSold(nftAddress, tokenId, listItem.price, msg.sender);
    }
}
