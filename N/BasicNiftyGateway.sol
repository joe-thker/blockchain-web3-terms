// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title BasicNiftyGateway
/// @notice A simple NFT drop contract inspired by Nifty Gateway where the owner mints NFTs.
contract BasicNiftyGateway is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);

    constructor(address initialOwner)
        ERC721("Basic Nifty NFT", "BNFT")
        Ownable(initialOwner)
    {}

    /// @notice Mint a new NFT with a metadata URI.
    /// @param to The recipient address.
    /// @param tokenURI The metadata URI.
    function mintNFT(address to, string calldata tokenURI) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        nextTokenId++;
        emit NFTMinted(to, tokenId, tokenURI);
    }
}
