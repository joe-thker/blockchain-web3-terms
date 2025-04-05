// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FanTokenMulti
 * @dev ERC1155 multi-token contract for Fan Tokens.
 * Different token IDs can represent different fan rewards or membership tiers.
 */
contract FanTokenMulti is ERC1155, Ownable {
    // Mapping from token ID to total supply minted.
    mapping(uint256 => uint256) public totalSupply;
    // Optional maximum supply per token ID.
    mapping(uint256 => uint256) public maxSupply;

    event MaxSupplyUpdated(uint256 tokenId, uint256 maxSupply);

    /**
     * @dev Constructor sets the base URI for all token types.
     * @param uri_ Base URI for token metadata.
     */
    constructor(string memory uri_) ERC1155(uri_) Ownable(msg.sender) {}

    /**
     * @dev Allows the owner to mint tokens of a specific type.
     * @param tokenId The ID of the token type to mint.
     * @param amount The amount to mint.
     */
    function mint(uint256 tokenId, uint256 amount) external onlyOwner {
        if (maxSupply[tokenId] > 0) {
            require(totalSupply[tokenId] + amount <= maxSupply[tokenId], "Exceeds max supply");
        }
        totalSupply[tokenId] += amount;
        _mint(msg.sender, tokenId, amount, "");
    }

    /**
     * @dev Allows the owner to set a maximum supply for a specific token type.
     * @param tokenId The ID of the token type.
     * @param _maxSupply The maximum supply for that token type.
     */
    function setMaxSupply(uint256 tokenId, uint256 _maxSupply) external onlyOwner {
        maxSupply[tokenId] = _maxSupply;
        emit MaxSupplyUpdated(tokenId, _maxSupply);
    }
}
