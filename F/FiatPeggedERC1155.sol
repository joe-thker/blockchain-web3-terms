// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FiatPeggedMultiToken
 * @dev ERC1155 token representing multiple fiat-backed assets.
 * Each token ID can represent a different fiat asset (e.g., USD, EUR) or voucher type.
 */
contract FiatPeggedMultiToken is ERC1155, Ownable {
    // Mapping from token ID to fiat value backing the token issuance.
    mapping(uint256 => uint256) public fiatValue;

    event TokenMinted(address indexed to, uint256 id, uint256 amount, uint256 fiatValue);

    /**
     * @dev Constructor sets the base URI for token metadata.
     * @param uri_ Base URI for token metadata.
     */
    constructor(string memory uri_) ERC1155(uri_) Ownable(msg.sender) {}

    /**
     * @dev Mints tokens for a specific token ID to a specified address.
     * Can only be called by the owner.
     * @param to Address that will receive the tokens.
     * @param id Token ID representing a fiat asset.
     * @param amount Amount of tokens to mint.
     * @param value Fiat value backing this token issuance (in smallest unit).
     */
    function mint(address to, uint256 id, uint256 amount, uint256 value) external onlyOwner {
        _mint(to, id, amount, "");
        fiatValue[id] = value;
        emit TokenMinted(to, id, amount, value);
    }
    
    /**
     * @dev Mints tokens in batch for multiple token IDs.
     * Can only be called by the owner.
     * @param to Address that will receive the tokens.
     * @param ids Array of token IDs.
     * @param amounts Array of amounts corresponding to each token ID.
     * @param values Array of fiat values corresponding to each token ID.
     * @param data Additional data with no specified format.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, uint256[] memory values, bytes memory data) external onlyOwner {
        require(ids.length == amounts.length && ids.length == values.length, "Array length mismatch");
        _mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            fiatValue[ids[i]] = values[i];
            emit TokenMinted(to, ids[i], amounts[i], values[i]);
        }
    }
}
