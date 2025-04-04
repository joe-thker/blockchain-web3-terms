// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract GemCollectible is ERC721URIStorage {
    uint256 public nextId;

    constructor() ERC721("GemCollectible", "GEMNFT") {}

    function mint(string memory uri) external {
        uint256 tokenId = nextId++;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }
}
