// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NickSzaboLegacy
/// @notice This contract represents Nick Szabo’s legacy through NFTs.
/// Each NFT minted in this contract symbolizes an aspect of Nick Szabo’s contributions to digital contracts and cryptocurrencies.
contract NickSzaboLegacy is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;

    event LegacyMinted(address indexed to, uint256 indexed tokenId, string tokenURI);

    /// @notice Constructor sets the token name, symbol, and assigns initial ownership.
    /// @param initialOwner The address that will receive ownership.
    constructor(address initialOwner)
        ERC721("Nick Szabo Legacy", "NSL")
        Ownable(initialOwner)
    {}

    /// @notice Mint a new legacy NFT.
    /// @dev Only callable by the contract owner.
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
