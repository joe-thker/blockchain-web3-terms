// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title BasicNFTRoyalties
/// @notice An ERC721 NFT contract implementing EIP‑2981 with a single royalty setting for all tokens.
contract BasicNFTRoyalties is ERC721, IERC2981, Ownable {
    uint256 public nextTokenId;
    address private _royaltyReceiver;
    uint96 private _royaltyFeeBasisPoints; // Fee in basis points (out of 10,000)

    /// @notice Constructor sets the initial royalty settings and assigns ownership.
    /// @param initialOwner The address for contract ownership.
    /// @param royaltyReceiver The address that will receive royalty payments.
    /// @param royaltyFeeBasisPoints The royalty fee in basis points (e.g., 500 = 5%).
    constructor(
        address initialOwner,
        address royaltyReceiver,
        uint96 royaltyFeeBasisPoints
    )
        ERC721("Basic NFT Royalties", "BASICNFT")
        Ownable(initialOwner)
    {
        _royaltyReceiver = royaltyReceiver;
        _royaltyFeeBasisPoints = royaltyFeeBasisPoints;
    }

    /// @notice Mint a new NFT to a given address (onlyOwner).
    function mint(address to) external onlyOwner {
        _mint(to, nextTokenId);
        nextTokenId++;
    }

    /// @notice EIP‑2981 royaltyInfo implementation.
    /// @param /* tokenId */ The NFT asset queried (unused in this implementation).
    /// @param salePrice The sale price of the NFT.
    /// @return receiver The address of the royalty receiver.
    /// @return royaltyAmount The royalty amount (salePrice * royaltyFee / 10000).
    function royaltyInfo(uint256 /* tokenId */, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * _royaltyFeeBasisPoints) / 10000;
    }

    /// @notice Override supportsInterface to include support for IERC2981.
    /// We list both ERC721 and IERC165 because ERC721 implements IERC165.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
