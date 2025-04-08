// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FishMultiToken
 * @dev ERC1155 token representing different fish species.
 * Each token ID represents a specific fish species; a user’s balance of that token ID indicates
 * how many fish of that species they have caught.
 */
contract FishMultiToken is ERC1155, Ownable {
    // Mapping from token ID to the fish species name.
    mapping(uint256 => string) public speciesName;
    // Internal counter for new token IDs.
    uint256 private _nextTokenId;

    event SpeciesCreated(uint256 indexed tokenId, string name);
    event FishCaught(address indexed catcher, uint256 indexed tokenId, uint256 amount, string species);

    /**
     * @dev Constructor sets the base URI for token metadata.
     * @param baseURI The base URI for all token metadata.
     */
    constructor(string memory baseURI) ERC1155(baseURI) Ownable(msg.sender) {
        _nextTokenId = 1;
    }

    /**
     * @notice Creates a new fish species with a unique token ID.
     * @param name The name of the fish species (e.g., "Trout").
     * @return tokenId The token ID assigned to the new species.
     */
    function createSpecies(string memory name) external onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId;
        _nextTokenId++;
        speciesName[tokenId] = name;
        emit SpeciesCreated(tokenId, name);
    }

    /**
     * @notice Allows a user to "catch" fish of a certain species.
     * Mints a specified amount of tokens for the given token ID to the caller.
     * @param tokenId The token ID representing the fish species.
     * @param amount The number of fish caught.
     */
    function catchFish(uint256 tokenId, uint256 amount) external {
        require(bytes(speciesName[tokenId]).length > 0, "Species does not exist");
        _mint(msg.sender, tokenId, amount, "");
        emit FishCaught(msg.sender, tokenId, amount, speciesName[tokenId]);
    }
}
