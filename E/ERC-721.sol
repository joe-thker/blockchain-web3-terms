// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DynamicERC721
/// @notice A dynamic and optimized ERC721 token contract with mint, burn, and tokenURI management.
/// Only the contract owner can mint, burn, or update token URIs.
contract DynamicERC721 is ERC721URIStorage, Ownable {
    // Auto-incremented token ID tracker.
    uint256 private _nextTokenId;

    // --- Events ---
    event TokenMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event TokenBurned(uint256 indexed tokenId);

    /**
     * @notice Constructor initializes the ERC721 token with a name and symbol.
     * The deployer is set as the initial owner.
     * @param name_ The name of the token collection.
     * @param symbol_ The symbol of the token collection.
     */
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        _nextTokenId = 1; // Start token IDs at 1
    }

    /**
     * @notice Mints a new token to a specified address with a token URI.
     * @dev Only the owner can mint tokens.
     * @param to The address that will receive the token.
     * @param tokenURI_ The metadata URI for the token.
     * @return tokenId The token ID of the newly minted token.
     */
    function mint(address to, string calldata tokenURI_)
        external
        onlyOwner
        returns (uint256 tokenId)
    {
        require(to != address(0), "Cannot mint to zero address");
        tokenId = _nextTokenId;
        _nextTokenId++;

        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        emit TokenMinted(to, tokenId, tokenURI_);
    }

    /**
     * @notice Checks whether a token exists.
     * @param tokenId The token ID to check.
     * @return exists True if the token exists, false otherwise.
     */
    function tokenExists(uint256 tokenId) public view returns (bool exists) {
        // ownerOf(tokenId) reverts for non-existent tokens, so we use try/catch.
        try this.ownerOf(tokenId) returns (address owner) {
            exists = owner != address(0);
        } catch {
            exists = false;
        }
    }

    /**
     * @notice Burns a token.
     * @dev Only the owner can burn tokens.
     * @param tokenId The token ID to burn.
     */
    function burn(uint256 tokenId) external onlyOwner {
        require(tokenExists(tokenId), "Token does not exist");
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }

    /**
     * @notice Updates the token URI for a given token.
     * @dev Only the owner can update token URIs.
     * @param tokenId The token ID to update.
     * @param newTokenURI The new metadata URI.
     */
    function updateTokenURI(uint256 tokenId, string calldata newTokenURI) external onlyOwner {
        require(tokenExists(tokenId), "Token does not exist");
        _setTokenURI(tokenId, newTokenURI);
    }
}
