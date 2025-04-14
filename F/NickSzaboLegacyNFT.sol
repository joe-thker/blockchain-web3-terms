// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NickSzaboLegacyNFT
/// @notice An ERC721 contract that mints NFTs symbolizing Nick Szabo’s legacy.
contract NickSzaboLegacyNFT is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;

    event LegacyMinted(address indexed to, uint256 indexed tokenId, string tokenURI);

    /// @notice Constructor sets the token name, symbol, and ownership.
    /// @param initialOwner The owner of the contract.
    constructor(address initialOwner)
        ERC721("Nick Szabo Legacy", "NSL")
        Ownable(initialOwner)
    {}

    /// @notice Mint a new legacy NFT.
    /// @param to The recipient address.
    /// @param tokenURI The metadata URI for the NFT.
    function mintLegacy(address to, string calldata tokenURI) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        nextTokenId++;
        emit LegacyMinted(to, tokenId, tokenURI);
    }
}
