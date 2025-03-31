// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title CryptoPunks
/// @notice A simplified ERC721 implementation inspired by CryptoPunks.
/// This contract is dynamic (sale parameters are adjustable), optimized (using ERC721Enumerable for efficient token tracking),
/// and secure (using Ownable and ReentrancyGuard for access control and reentrancy protection).
contract CryptoPunks is ERC721Enumerable, Ownable, ReentrancyGuard {
    // Maximum supply of CryptoPunks.
    uint256 public constant MAX_PUNKS = 10000;
    // Price per punk (in wei).
    uint256 public mintPrice = 0.05 ether;
    // Sale status.
    bool public saleActive = false;

    // Optional: mapping from token ID to metadata (can be used to store on-chain traits or links to off-chain metadata)
    mapping(uint256 => string) public punkMetadata;

    // --- Events ---
    event SaleStatusToggled(bool saleActive);
    event MintPriceUpdated(uint256 newPrice);
    event PunkMinted(address indexed minter, uint256 indexed tokenId);
    event MetadataUpdated(uint256 indexed tokenId, string metadata);

    /// @notice Constructor sets the token name and symbol.
    constructor() ERC721("CryptoPunks", "PUNK") Ownable(msg.sender) {
        // Owner is set via Ownable.
    }

    /// @notice Toggles the sale active status.
    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
        emit SaleStatusToggled(saleActive);
    }

    /// @notice Sets the mint price.
    /// @param newPrice The new mint price in wei.
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    /// @notice Mints one or more punks. Requires the sale to be active.
    /// @param numberOfTokens The number of tokens to mint.
    function mintPunk(uint256 numberOfTokens) external payable nonReentrant {
        require(saleActive, "Sale is not active");
        require(numberOfTokens > 0, "Must mint at least one");
        require(totalSupply() + numberOfTokens <= MAX_PUNKS, "Exceeds maximum supply");
        require(msg.value >= mintPrice * numberOfTokens, "Insufficient Ether sent");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply() + 1; // Token IDs start at 1.
            _safeMint(msg.sender, tokenId);
            // Optionally, initialize default metadata.
            punkMetadata[tokenId] = "Default Metadata";
            emit PunkMinted(msg.sender, tokenId);
        }
    }

    /// @notice Allows the owner to mint tokens (for reserves, giveaways, etc.).
    /// @param to The recipient address.
    /// @param numberOfTokens The number of tokens to mint.
    function ownerMint(address to, uint256 numberOfTokens) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(totalSupply() + numberOfTokens <= MAX_PUNKS, "Exceeds maximum supply");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(to, tokenId);
            punkMetadata[tokenId] = "Default Metadata";
            emit PunkMinted(to, tokenId);
        }
    }

    /// @notice Updates the metadata for a specific punk.
    /// @param tokenId The token ID to update.
    /// @param metadata The new metadata string.
    function updateMetadata(uint256 tokenId, string calldata metadata) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        punkMetadata[tokenId] = metadata;
        emit MetadataUpdated(tokenId, metadata);
    }

    /// @notice Withdraws Ether from the contract.
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Fallback function to receive Ether.
    receive() external payable {}
    
    /// @notice Fallback function for non-empty calldata.
    fallback() external payable {}
}
