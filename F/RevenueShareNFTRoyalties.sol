// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title RevenueShareNFTRoyalties
/// @notice An ERC721 NFT contract that supports EIP-2981 royalties with revenue sharing.
/// Each NFT stores a royalty split between a primary and secondary receiver.
contract RevenueShareNFTRoyalties is ERC721, IERC2981, Ownable {
    struct RoyaltySplit {
        address primaryReceiver;
        address secondaryReceiver;
        uint96 primaryFeeBasisPoints;   // Primary fee in basis points
        uint96 secondaryFeeBasisPoints; // Secondary fee in basis points
    }
    
    mapping(uint256 => RoyaltySplit) public tokenRoyaltySplits;
    uint256 public nextTokenId;

    constructor(address initialOwner)
        ERC721("RevenueShare NFT", "RSHNFT")
        Ownable(initialOwner)
    {}

    /// @notice Mint an NFT and set its royalty split.
    /// @param to The address receiving the NFT.
    /// @param primaryReceiver The primary royalty receiver.
    /// @param secondaryReceiver The secondary royalty receiver.
    /// @param primaryFeeBasisPoints The primary fee (in basis points).
    /// @param secondaryFeeBasisPoints The secondary fee (in basis points).
    function mint(
        address to,
        address primaryReceiver,
        address secondaryReceiver,
        uint96 primaryFeeBasisPoints,
        uint96 secondaryFeeBasisPoints
    ) external onlyOwner {
        require(primaryFeeBasisPoints + secondaryFeeBasisPoints <= 10000, "Total fee exceeds 100%");
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        tokenRoyaltySplits[tokenId] = RoyaltySplit(primaryReceiver, secondaryReceiver, primaryFeeBasisPoints, secondaryFeeBasisPoints);
        nextTokenId++;
    }

    /// @notice EIP-2981 royaltyInfo implementation.
    /// Returns the primary receiver's share. Full split details can be obtained via getRoyaltySplit.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltySplit memory split = tokenRoyaltySplits[tokenId];
        receiver = split.primaryReceiver;
        royaltyAmount = (salePrice * split.primaryFeeBasisPoints) / 10000;
    }

    /// @notice Returns the complete royalty split for a token.
    function getRoyaltySplit(uint256 tokenId)
        external
        view
        returns (address primary, address secondary, uint96 primaryFee, uint96 secondaryFee)
    {
        RoyaltySplit memory split = tokenRoyaltySplits[tokenId];
        return (split.primaryReceiver, split.secondaryReceiver, split.primaryFeeBasisPoints, split.secondaryFeeBasisPoints);
    }

    /// @notice Override supportsInterface to declare support for EIP-2981.
    /// This override specifies both ERC721 and IERC165 as overridden contracts.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
