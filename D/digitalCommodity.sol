// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DigitalCommodity
/// @notice A dynamic, optimized ERC1155-based contract for digital commodities. The contract owner can
/// create new commodity types (token IDs) with unique URIs, mint or burn quantities, and update URIs if needed.
contract DigitalCommodity is ERC1155, Ownable {
    /// @notice A mapping from token ID to a boolean indicating whether it has been initialized.
    /// We use this to track which IDs are “active” (i.e., recognized commodity types).
    mapping(uint256 => bool) public tokenIdActive;

    /// @notice Constructor that sets a base URI pattern for all token types. 
    /// Deployer is set as initial owner by calling Ownable(msg.sender).
    /// @param baseURI The base URI for metadata. If each token type has unique URIs, 
    /// you can store them in a separate mapping or use the token ID in the URI string.
    constructor(string memory baseURI) ERC1155(baseURI) Ownable(msg.sender) {}

    /// @notice Allows the owner to set a new base URI for all tokens. 
    /// For dynamic metadata or if each token ID has a unique URI, 
    /// you could store a separate per-ID URI, but for simplicity we use ERC1155’s base URI pattern.
    /// @param newBaseURI The new base URI to set.
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setURI(newBaseURI);
    }

    /// @notice Creates or marks a token ID as active, representing a new commodity type. 
    /// Once active, it can be minted, burned, or transferred. 
    /// This function simply records it as an existing ID (the metadata is derived from the base URI).
    /// @param tokenId The unique ID of the commodity type to activate.
    function createCommodity(uint256 tokenId) external onlyOwner {
        require(!tokenIdActive[tokenId], "Commodity type already active");
        tokenIdActive[tokenId] = true;
    }

    /// @notice Mints new tokens (digital commodity units) of a given token ID to the specified address.
    /// @param to The address receiving the minted tokens.
    /// @param tokenId The token ID (commodity type) being minted.
    /// @param amount The quantity to mint.
    /// @param data Optional data payload if needed (can be empty).
    function mintCommodity(address to, uint256 tokenId, uint256 amount, bytes memory data) 
        external 
        onlyOwner
    {
        require(tokenIdActive[tokenId], "Commodity type not active");
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Mint amount must be > 0");

        _mint(to, tokenId, amount, data);
    }

    /// @notice Burns a certain quantity of tokens from a specified address.
    /// For an ERC1155, burning requires either the token holder or an operator/approval. 
    /// Only the contract owner can forcibly burn from any address here – you can adjust logic if needed.
    /// @param from The address from which to burn tokens.
    /// @param tokenId The token ID (commodity type).
    /// @param amount The quantity to burn.
    function burnCommodity(address from, uint256 tokenId, uint256 amount) external {
        require(
            msg.sender == owner() || msg.sender == from, 
            "Not authorized to burn"
        );
        require(tokenIdActive[tokenId], "Commodity type not active");
        require(amount > 0, "Burn amount must be > 0");
        _burn(from, tokenId, amount);
    }

    /// @notice Updates a token ID to inactive, effectively disallowing future mints of that commodity type. 
    /// Existing minted commodities can still be transferred or burned. 
    /// @param tokenId The ID to deactivate.
    function deactivateCommodity(uint256 tokenId) external onlyOwner {
        require(tokenIdActive[tokenId], "Commodity not active");
        tokenIdActive[tokenId] = false;
    }

    /// @notice Batch version of minting for multiple token IDs at once, if desired.
    /// This leverages ERC1155’s _mintBatch internally.
    /// @param to The recipient address for all minted IDs.
    /// @param ids The array of token IDs.
    /// @param amounts The array of amounts corresponding to each token ID.
    /// @param data Optional data payload.
    function mintBatchCommodity(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        external
        onlyOwner
    {
        require(to != address(0), "Cannot mint to zero address");
        require(ids.length == amounts.length, "Mismatched ids/amounts array length");
        for (uint256 i = 0; i < ids.length; i++) {
            require(tokenIdActive[ids[i]], "Commodity type not active");
            require(amounts[i] > 0, "Each mint amount must be > 0");
        }
        _mintBatch(to, ids, amounts, data);
    }

    /// @notice Returns whether a specific token ID is active in the ecosystem.
    /// @param tokenId The ID to check.
    /// @return True if active, false otherwise.
    function isActive(uint256 tokenId) external view returns (bool) {
        return tokenIdActive[tokenId];
    }
}
