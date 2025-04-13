// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FuturesNFT is ERC721 {
    uint256 public idCounter;
    mapping(uint256 => uint256) public margin;
    mapping(uint256 => bool) public isLong;

    constructor() ERC721("Futures Position", "FUTP") {}

    function open(bool _isLong) external payable {
        require(msg.value > 0);
        uint256 id = ++idCounter;
        _mint(msg.sender, id);
        margin[id] = msg.value;
        isLong[id] = _isLong;
    }

    function getPosition(uint256 tokenId) external view returns (bool, uint256) {
        return (isLong[tokenId], margin[tokenId]);
    }
}
