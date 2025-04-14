// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DynamicNFTRoyalties
/// @notice An ERC721 NFT contract where royalty fees change dynamically over time,
///         calculated based on the time elapsed since minting.
///         Implements EIP-2981 for royalty information.
contract DynamicNFTRoyalties is ERC721, IERC2981, Ownable {
    struct TokenData {
        uint256 mintTime;
        uint96 baseFeeBasisPoints;
        uint96 incrementalFeePerDay; // Additional fee per day (in basis points)
        address receiver;
    }

    mapping(uint256 => TokenData) public tokenData;
    uint256 public nextTokenId;

    /// @notice Constructor sets the token name, symbol, and initial owner.
    /// @param initialOwner The address that will receive ownership.
    constructor(address initialOwner)
        ERC721("Dynamic NFT Royalties", "DYNFT")
        Ownable(initialOwner)
    {}

    /// @notice Mint a new NFT with dynamic royalty settings.
    /// @param to The recipient address.
    /// @param royaltyReceiver The address to receive royalty payments.
    /// @param baseFeeBasisPoints The base royalty fee in basis points.
    /// @param incrementalFeePerDay The additional royalty fee (basis points) added per day after minting.
    function mint(
        address to,
        address royaltyReceiver,
        uint96 baseFeeBasisPoints,
        uint96 incrementalFeePerDay
    ) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        tokenData[tokenId] = TokenData({
            mintTime: block.timestamp,
            baseFeeBasisPoints: baseFeeBasisPoints,
            incrementalFeePerDay: incrementalFeePerDay,
            receiver: royaltyReceiver
        });
        nextTokenId++;
    }

    /// @notice EIP-2981 royaltyInfo implementation.
    /// @param tokenId The token identifier.
    /// @param salePrice The sale price of the NFT.
    /// @return receiver The address to which royalties should be paid.
    /// @return royaltyAmount The calculated royalty amount.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        TokenData memory data = tokenData[tokenId];
        uint256 daysElapsed = (block.timestamp - data.mintTime) / 1 days;
        uint256 totalFeeBasisPoints = uint256(data.baseFeeBasisPoints) + (uint256(data.incrementalFeePerDay) * daysElapsed);
        // Cap total fee at 100% (10000 basis points) to avoid overflow.
        if (totalFeeBasisPoints > 10000) {
            totalFeeBasisPoints = 10000;
        }
        receiver = data.receiver;
        royaltyAmount = (salePrice * totalFeeBasisPoints) / 10000;
    }

    /// @notice Override supportsInterface to declare support for IERC2981.
    /// We specify ERC721 and IERC165 (which ERC721 implements) as the overridden contracts.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
