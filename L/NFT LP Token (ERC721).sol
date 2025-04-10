// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTLPToken is ERC721 {
    uint256 public tokenId;

    constructor() ERC721("NFT LP", "NFTLP") {}

    function mint(address to) external {
        tokenId++;
        _mint(to, tokenId);
    }

    function burn(uint256 id) external {
        require(ownerOf(id) == msg.sender, "Not owner");
        _burn(id);
    }
}
