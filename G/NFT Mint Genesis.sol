pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTGenesis is ERC721 {
    uint256 public nextId;

    constructor() ERC721("GenesisNFT", "GNFT") {}

    function mintGenesis(string memory uri) external {
        _mint(msg.sender, nextId);
        nextId++;
        // You can link URI with a mapping if needed
    }
}
