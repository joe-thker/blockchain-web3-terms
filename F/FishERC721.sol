// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FishERC721
 * @dev ERC721 token where each token represents a unique fish.
 */
contract FishERC721 is ERC721, Ownable {
    struct Fish {
        string name;
        string species;
        uint256 weightInGrams;
    }

    uint256 private _nextTokenId = 1;
    mapping(uint256 => Fish) private _fishData;

    event FishCaught(
        address indexed catcher,
        uint256 indexed tokenId,
        string name,
        string species,
        uint256 weightInGrams
    );

    constructor() ERC721("FishNFT", "FISH") Ownable(msg.sender) {}

    function catchFish(
        string memory name,
        string memory species,
        uint256 weightInGrams
    ) external {
        require(weightInGrams > 0, "Fish weight must be > 0");
        uint256 tokenId = _nextTokenId++;
        _fishData[tokenId] = Fish(name, species, weightInGrams);
        _safeMint(msg.sender, tokenId);

        emit FishCaught(msg.sender, tokenId, name, species, weightInGrams);
    }

    function getFishInfo(uint256 tokenId)
        external
        view
        returns (string memory, string memory, uint256)
    {
        // ✅ Replaces _exists(tokenId) check
        require(_ownerOf(tokenId) != address(0), "Fish does not exist");

        Fish memory fish = _fishData[tokenId];
        return (fish.name, fish.species, fish.weightInGrams);
    }
}
