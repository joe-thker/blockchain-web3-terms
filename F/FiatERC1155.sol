// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FiatMultiToken
 * @dev ERC1155 token representing multiple fiat-backed assets.
 * Different token IDs can represent various fiat assets or denominations.
 * The owner (custodian) can mint tokens for any token ID.
 */
contract FiatMultiToken is ERC1155, Ownable {
    /**
     * @dev Constructor sets the base URI for token metadata.
     * @param uri_ Base URI for token metadata.
     */
    constructor(string memory uri_)
        ERC1155(uri_)
        Ownable(msg.sender)
    {}

    /**
     * @dev Mints tokens for a specific token ID to a specified address.
     * Can only be called by the owner.
     * @param to Address that will receive the tokens.
     * @param id Token ID representing a fiat asset.
     * @param amount Amount of tokens to mint.
     * @param data Additional data with no specified format.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyOwner {
        _mint(to, id, amount, data);
    }
    
    /**
     * @dev Mints tokens in batch for multiple token IDs.
     * Can only be called by the owner.
     * @param to Address that will receive the tokens.
     * @param ids Array of token IDs.
     * @param amounts Array of amounts corresponding to each token ID.
     * @param data Additional data with no specified format.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }
}
