// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title PerTokenNFTRoyalties
/// @notice An ERC721 NFT contract where each token has its own royalty settings.
/// Implements EIP-2981 for per-token royalty information.
contract PerTokenNFTRoyalties is ERC721, IERC2981, Ownable {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFeeBasisPoints; // Fee in basis points (out of 10,000)
    }
    
    mapping(uint256 => RoyaltyInfo) private _tokenRoyalties;
    uint256 public nextTokenId;

    constructor(address initialOwner)
        ERC721("Per-Token NFT Royalties", "PERNFT")
        Ownable(initialOwner)
    {}

    /// @notice Mint an NFT with custom royalty information.
    /// @param to The address to mint the NFT to.
    /// @param royaltyReceiver The address to receive royalty payments.
    /// @param royaltyFeeBasisPoints The royalty fee in basis points.
    function mint(
        address to,
        address royaltyReceiver,
        uint96 royaltyFeeBasisPoints
    ) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        _tokenRoyalties[tokenId] = RoyaltyInfo(royaltyReceiver, royaltyFeeBasisPoints);
        nextTokenId++;
    }

    /// @notice EIP-2981 royaltyInfo implementation.
    /// @param tokenId The ID of the NFT.
    /// @param salePrice The sale price of the NFT.
    /// @return receiver The address to receive the royalty.
    /// @return royaltyAmount The royalty amount (salePrice * fee / 10000).
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory info = _tokenRoyalties[tokenId];
        receiver = info.receiver;
        royaltyAmount = (salePrice * info.royaltyFeeBasisPoints) / 10000;
    }

    /// @notice Override supportsInterface to include support for IERC2981.
    /// Note: We specify both ERC721 and IERC165 here.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
