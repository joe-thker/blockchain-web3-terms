// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NiftyGateway
/// @notice An NFT drop and marketplace contract inspired by Nifty Gateway.
/// The owner (platform) can mint NFTs. NFT holders can list tokens for sale.
/// Buyers can purchase NFTs by paying the sale price, where a platform fee is deducted.
contract NiftyGateway is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;
    // Platform fee in basis points (e.g., 250 = 2.5%)
    uint256 public platformFeeBasisPoints = 250;
    // Mapping from tokenId to sale price (in wei). Zero indicates not listed.
    mapping(uint256 => uint256) public tokenSalePrice;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event NFTListed(uint256 indexed tokenId, uint256 salePrice);
    event NFTSaleCanceled(uint256 indexed tokenId);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 salePrice);

    /// @notice Constructor sets the token name, symbol and assigns initial ownership.
    /// @param initialOwner The address to set as the owner (platform).
    constructor(address initialOwner) ERC721("NiftyGateway NFT", "NGNFT") Ownable(initialOwner) {}

    /// @notice Mint a new NFT.
    /// @param to The recipient address.
    /// @param tokenURI The metadata URI for the NFT.
    function mintNFT(address to, string calldata tokenURI) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        nextTokenId++;
        emit NFTMinted(to, tokenId, tokenURI);
    }

    /// @notice List an NFT for sale.
    /// @param tokenId The NFT id.
    /// @param salePrice The sale price in wei (must be > 0).
    function listForSale(uint256 tokenId, uint256 salePrice) external {
        require(ownerOf(tokenId) == msg.sender, "Not the NFT owner");
        require(salePrice > 0, "Sale price must be > 0");
        tokenSalePrice[tokenId] = salePrice;
        emit NFTListed(tokenId, salePrice);
    }

    /// @notice Cancel an NFT sale listing.
    /// @param tokenId The NFT id.
    function cancelSale(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not the NFT owner");
        require(tokenSalePrice[tokenId] > 0, "NFT is not listed");
        tokenSalePrice[tokenId] = 0;
        emit NFTSaleCanceled(tokenId);
    }

    /// @notice Buy a listed NFT.
    /// Buyer sends ETH equal or greater than the sale price.
    /// The sale amount is split between the seller and the platform fee.
    /// Any extra ETH is refunded to the buyer.
    /// @param tokenId The NFT id.
    function buyNFT(uint256 tokenId) external payable {
        uint256 salePrice = tokenSalePrice[tokenId];
        require(salePrice > 0, "NFT not listed for sale");
        require(msg.value >= salePrice, "Insufficient funds");

        address seller = ownerOf(tokenId);
        require(seller != msg.sender, "Seller cannot be buyer");

        // Clear the listing.
        tokenSalePrice[tokenId] = 0;

        // Calculate the platform fee.
        uint256 fee = (salePrice * platformFeeBasisPoints) / 10000;
        uint256 sellerProceeds = salePrice - fee;

        // Transfer the NFT.
        _transfer(seller, msg.sender, tokenId);

        // Transfer ETH: seller gets proceeds and platform (contract owner) receives the fee.
        payable(seller).transfer(sellerProceeds);
        payable(owner()).transfer(fee);

        // Refund any excess ETH sent.
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }

        emit NFTSold(tokenId, msg.sender, salePrice);
    }

    /// @notice Set the platform fee (in basis points). Only the owner can call.
    /// @param newFeeBasisPoints The new fee, where 10000 represents 100%.
    function setPlatformFee(uint256 newFeeBasisPoints) external onlyOwner {
        require(newFeeBasisPoints <= 1000, "Fee too high");
        platformFeeBasisPoints = newFeeBasisPoints;
    }
}
