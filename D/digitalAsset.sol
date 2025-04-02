// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DigitalAsset
/// @notice A dynamic and optimized ERC721 NFT contract for digital assets. The owner can mint tokens,
/// update token URIs, and burn tokens. Users can transfer tokens normally via standard ERC721 methods.
contract DigitalAsset is ERC721URIStorage, Ownable {
    // Next token ID to be minted
    uint256 public nextTokenId;

    /// @notice Constructor sets the ERC721 token name and symbol. Deployer is initial owner.
    /// @param name_ The name of the NFT collection (e.g., "MyDigitalAsset").
    /// @param symbol_ The symbol of the NFT (e.g., "MDA").
    constructor(string memory name_, string memory symbol_) 
        ERC721(name_, symbol_) 
        Ownable(msg.sender) 
    {}

    /// @notice Mints a new token to a specified address with a given URI. Only the contract owner can mint.
    /// @param to The address receiving the new token.
    /// @param tokenURI The metadata URI for the token.
    /// @return tokenId The ID of the newly minted token.
    function mint(address to, string calldata tokenURI) 
        external 
        onlyOwner 
        returns (uint256 tokenId) 
    {
        require(to != address(0), "Cannot mint to zero address");

        tokenId = ++nextTokenId; // increment first, then use
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    /// @notice Burns (destroys) an existing token. 
    /// Either the token’s owner/approved or the contract owner can burn the token.
    /// @param tokenId The ID of the token to burn.
    function burn(uint256 tokenId) external {
        // The caller must be either the token’s owner/approved or the contract owner
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) || _msgSender() == owner(),
            "Not authorized to burn"
        );
        _burn(tokenId);
    }

    /// @notice Updates the token URI for an existing token. Only the contract owner can update URIs.
    /// @param tokenId The ID of the token.
    /// @param newURI The new URI for the token.
    function updateTokenURI(uint256 tokenId, string calldata newURI) 
        external 
        onlyOwner 
    {
        require(_exists(tokenId), "Token does not exist");
        _setTokenURI(tokenId, newURI);
    }
}
