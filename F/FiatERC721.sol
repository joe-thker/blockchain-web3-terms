// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FiatNFT
 * @dev ERC721 token representing a fiat-backed asset or claim.
 * The owner (e.g., a custodian) can mint NFTs representing fiat assets.
 */
contract FiatNFT is ERC721Enumerable, Ownable {
    uint256 private _nextTokenId;

    /**
     * @dev Constructor sets the NFT name and symbol and assigns the deployer as owner.
     */
    constructor() ERC721("Fiat NFT", "FIATNFT") Ownable(msg.sender) {
        _nextTokenId = 1;
    }
    
    /**
     * @dev Mints a new NFT to a specified address.
     * Can only be called by the owner.
     * @param to Address that will receive the NFT.
     */
    function mint(address to) external onlyOwner {
        uint256 tokenId = _nextTokenId;
        _safeMint(to, tokenId);
        _nextTokenId++;
    }
}
