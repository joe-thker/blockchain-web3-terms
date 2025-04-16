// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BasicNFT
 * @notice A simple ERC721 token representing non-fungible assets.
 *         Only the owner can mint tokens. A base URI is defined for metadata.
 */
contract BasicNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    string private _baseTokenURI;

    /**
     * @dev Constructor sets the token name, symbol, and the base URI for metadata.
     * Also passes the deployer's address to the Ownable constructor.
     * @param baseURI The base URI for token metadata.
     */
    constructor(string memory baseURI)
        ERC721("BasicNFT", "BNFT")
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Mint a new token.
     * @param to The address to receive the token.
     * @return tokenId The ID of the newly minted token.
     */
    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _mint(to, tokenId);
        _tokenIdCounter++;
        return tokenId;
    }

    /**
     * @notice Update the base URI.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Returns the base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
