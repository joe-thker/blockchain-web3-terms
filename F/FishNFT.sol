// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FishNFT
 * @dev ERC721 NFT where each token represents a unique fish.
 */
contract FishNFT is ERC721, Ownable {
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

    /**
     * @notice Catch a new fish (mint NFT).
     */
    function catchFish(
        string memory name,
        string memory species,
        uint256 weightInGrams
    ) external {
        require(weightInGrams > 0, "Weight must be > 0 grams");

        uint256 tokenId = _nextTokenId++;
        _fishData[tokenId] = Fish(name, species, weightInGrams);
        _safeMint(msg.sender, tokenId);

        emit FishCaught(msg.sender, tokenId, name, species, weightInGrams);
    }

    /**
     * @notice View fish info by tokenId.
     */
    function getFishInfo(uint256 tokenId) external view returns (string memory, string memory, uint256) {
        // ✅ Compatible with OpenZeppelin v5+
        require(_tokenExists(tokenId), "Fish does not exist");

        Fish memory fish = _fishData[tokenId];
        return (fish.name, fish.species, fish.weightInGrams);
    }

    /**
     * @dev Checks if token exists using try/catch on ownerOf.
     */
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        try this.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }
}
