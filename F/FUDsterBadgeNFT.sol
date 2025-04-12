// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FUDsterBadgeNFT is ERC721URIStorage, Ownable {
    uint256 public tokenId;

    constructor(address initialOwner) ERC721("FUD Badge", "FUDNFT") Ownable(initialOwner) {}

    function awardFUDBadge(address to, string memory uri) external onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        tokenId++;
    }
}
