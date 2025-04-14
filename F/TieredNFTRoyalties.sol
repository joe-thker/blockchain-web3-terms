// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TieredNFTRoyalties
/// @notice An ERC721 NFT contract where each NFT is assigned a tier with its own royalty settings.
/// Implements EIP-2981 for royalty information.
contract TieredNFTRoyalties is ERC721, IERC2981, Ownable {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFeeBasisPoints;
    }
    // Mapping from token ID to its tier.
    mapping(uint256 => uint8) public tokenTiers;
    // Royalty info for each tier.
    mapping(uint8 => RoyaltyInfo) public tierRoyaltyInfo;
    uint256 public nextTokenId;

    constructor(address initialOwner)
        ERC721("Tiered NFT Royalties", "TIERNFT")
        Ownable(initialOwner)
    {}

    /// @notice Mint an NFT and assign it to a tier.
    /// @param to The recipient address.
    /// @param tier The tier for the NFT.
    function mint(address to, uint8 tier) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        tokenTiers[tokenId] = tier;
        nextTokenId++;
    }

    /// @notice Set the default royalty information for a given tier.
    /// @param tier The tier identifier.
    /// @param receiver The royalty payment receiver.
    /// @param feeBasisPoints The royalty fee in basis points (out of 10,000).
    function setTierRoyalty(
        uint8 tier,
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        tierRoyaltyInfo[tier] = RoyaltyInfo(receiver, feeBasisPoints);
    }

    /// @notice EIP-2981 royaltyInfo implementation using tier-specific royalty info.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        uint8 tier = tokenTiers[tokenId];
        RoyaltyInfo memory info = tierRoyaltyInfo[tier];
        receiver = info.receiver;
        royaltyAmount = (salePrice * info.royaltyFeeBasisPoints) / 10000;
    }

    /// @notice Override supportsInterface to include support for EIP-2981.
    /// This override specifies that we override functions from both ERC721 and IERC165.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
