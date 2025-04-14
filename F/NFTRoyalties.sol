// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NFTWithRoyalties
/// @notice An ERC721 NFT contract with EIP-2981 royalties support.
/// All tokens share the same royalty configuration.
/// EIP-2981 specifies that a royalty payment is made to a given receiver
/// based on a sale price and a fee denominator of 10000 (basis points).
contract NFTWithRoyalties is ERC721, IERC2981, Ownable {
    uint256 public nextTokenId;
    // Royalty settings: all tokens will have the same royalty settings.
    address private _royaltyReceiver;
    uint96 private _royaltyFeeBasisPoints;

    /// @notice Constructor sets initial royalty settings and mints initial supply if desired.
    /// @param royaltyReceiver The address to receive royalty payments.
    /// @param royaltyFeeBasisPoints The royalty fee in basis points (out of 10000).
    constructor(address royaltyReceiver, uint96 royaltyFeeBasisPoints)
        ERC721("NFT with Royalties", "NFTROY")
        Ownable(msg.sender)
    {
        _royaltyReceiver = royaltyReceiver;
        _royaltyFeeBasisPoints = royaltyFeeBasisPoints;
    }

    /// @notice Mint a new token to a specified address. Only the owner can mint.
    /// @param to The address that receives the minted token.
    function mint(address to) external onlyOwner {
        _mint(to, nextTokenId);
        nextTokenId++;
    }

    /// @notice See EIP-2981: Returns royalty information for a token sale.
    /// @param /*tokenId*/ The NFT asset queried for royalty info (unused in this implementation).
    /// @param salePrice The sale price of the NFT.
    /// @return receiver The address of the royalty receiver.
    /// @return royaltyAmount The royalty amount calculated as salePrice * fee / 10000.
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
    /// @param interfaceId The interface identifier, as specified in ERC-165.
    /// @return True if the contract implements the requested interface.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        // IERC2981 interface id is: 0x2a55205a.
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Update the royalty receiver. Only the owner can update.
    /// @param newReceiver The new royalty receiver address.
    function setRoyaltyReceiver(address newReceiver) external onlyOwner {
        _royaltyReceiver = newReceiver;
    }

    /// @notice Update the royalty fee. Only the owner can update.
    /// @param newFeeBasisPoints The new royalty fee in basis points.
    function setRoyaltyFee(uint96 newFeeBasisPoints) external onlyOwner {
        _royaltyFeeBasisPoints = newFeeBasisPoints;
    }
}
