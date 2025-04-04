// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FallingKnifeERC721
 * @dev ERC721 token where each NFT has a "strength" value that is reduced on each transfer.
 * The reduction is calculated as:
 *   newStrength = currentStrength - (currentStrength * burnPercentage / 10000)
 * and is applied immediately before a token is transferred.
 */
contract FallingKnifeERC721 is ERC721, Ownable {
    // Mapping from tokenId to its strength value.
    mapping(uint256 => uint256) public tokenStrength;
    // Burn percentage in basis points (e.g., 500 means 5% reduction).
    uint256 public burnPercentage;
    // Internal counter for token IDs.
    uint256 private _nextTokenId;

    event BurnPercentageUpdated(uint256 newBurnPercentage);
    event StrengthReduced(uint256 tokenId, uint256 newStrength);

    /**
     * @dev Constructor sets the token name, symbol, and initial burn percentage.
     * @param _burnPercentage Burn percentage in basis points.
     */
    constructor(uint256 _burnPercentage)
        ERC721("Falling Knife NFT", "FKNFT")
        Ownable(msg.sender)
    {
        require(_burnPercentage <= 10000, "Invalid burn percentage");
        burnPercentage = _burnPercentage;
        _nextTokenId = 1;
    }

    /**
     * @dev Mint a new NFT with an initial strength.
     * @param initialStrength The starting strength value for the NFT.
     */
    function mint(uint256 initialStrength) external onlyOwner {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        tokenStrength[tokenId] = initialStrength;
    }

    /**
     * @dev Allows the owner to update the burn percentage.
     * @param newBurnPercentage New burn percentage in basis points.
     */
    function updateBurnPercentage(uint256 newBurnPercentage) external onlyOwner {
        require(newBurnPercentage <= 10000, "Invalid burn percentage");
        burnPercentage = newBurnPercentage;
        emit BurnPercentageUpdated(newBurnPercentage);
    }

    /**
     * @dev Internal function to apply the falling knife logic.
     * Reduces the token's strength by (currentStrength * burnPercentage / 10000)
     * and emits a StrengthReduced event.
     * @param tokenId The ID of the token whose strength will be reduced.
     */
    function _applyFallingKnife(uint256 tokenId) internal {
        uint256 currentStrength = tokenStrength[tokenId];
        uint256 reduction = (currentStrength * burnPercentage) / 10000;
        uint256 newStrength = currentStrength > reduction ? currentStrength - reduction : 0;
        tokenStrength[tokenId] = newStrength;
        emit StrengthReduced(tokenId, newStrength);
    }

    /**
     * @dev Overrides transferFrom to apply falling knife logic before transferring.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        _applyFallingKnife(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Overrides safeTransferFrom (without data) to apply falling knife logic before transferring.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        _applyFallingKnife(tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Overrides safeTransferFrom (with data) to apply falling knife logic before transferring.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        _applyFallingKnife(tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
