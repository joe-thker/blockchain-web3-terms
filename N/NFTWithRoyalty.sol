// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title NFTWithRoyalty
 * @notice An ERC721 token representing non-fungible assets with royalty support.
 *         Inherits ERC721Enumerable for token enumeration and ERC2981 for royalty information.
 */
contract NFTWithRoyalty is ERC721Enumerable, ERC2981, Ownable {
    uint256 private _nextTokenId = 1;
    string private _baseTokenURI;

    /**
     * @param baseURI The base URI for token metadata.
     * @param royaltyReceiver The address that will receive royalty payments.
     * @param royaltyFeeNumerator The fee numerator for royalties (in basis points).
     */
    constructor(
        string memory baseURI,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    )
        ERC721("NFTWithRoyalty", "NFWR")
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI;
        // Set default royalty information.
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
    }

    /**
     * @notice Mint a new token and assign it to `to`.
     * @param to The address that will receive the minted token.
     * @return tokenId The minted token ID.
     */
    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId;
        _safeMint(to, tokenId);
        _nextTokenId++;
        return tokenId;
    }

    /**
     * @notice Update the base URI.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Returns the base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Override supportsInterface to include ERC2981 interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
