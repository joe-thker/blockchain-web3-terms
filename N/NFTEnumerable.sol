// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin contracts.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTEnumerable
 * @notice An ERC721 token implementation with enumerable features.
 *         This contract allows the owner to mint tokens with automatically incrementing IDs.
 *         It also supports setting a base URI and optionally assigning a unique URI per token.
 */
contract NFTEnumerable is ERC721Enumerable, Ownable {
    // Counter for the next token ID.
    uint256 private _nextTokenId = 1;
    // Base URI for all token metadata.
    string private _baseTokenURI;
    // Optional mapping for token URIs (per-token override).
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev Constructor sets the token name, symbol, and initial base URI.
     * @param baseURI The base URI for token metadata.
     */
    constructor(string memory baseURI) ERC721("NFTEnumerable", "NFTE") {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Mint a new token and assign it to `to`.
     * @dev Only the contract owner can mint tokens.
     * @param to The address that will receive the minted token.
     * @return tokenId The newly minted token ID.
     */
    function mint(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId;
        _safeMint(to, tokenId);
        _nextTokenId++;
    }

    /**
     * @notice Update the base URI for token metadata.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Set the token URI for a specific token.
     * @dev This function allows the owner to override the base URI for a token.
     * @param tokenId The token ID.
     * @param tokenURI_ The token metadata URI.
     */
    function setTokenURI(uint256 tokenId, string memory tokenURI_) external onlyOwner {
        require(_exists(tokenId), "NFTEnumerable: URI set of nonexistent token");
        _tokenURIs[tokenId] = tokenURI_;
    }

    /**
     * @dev Override of the OpenZeppelin _baseURI() function to return the base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Returns the token URI for a given token.
     * @param tokenId The token ID.
     * @return A string with the token URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NFTEnumerable: URI query for nonexistent token");

        // Use token-specific URI if available.
        string memory tokenSpecificURI = _tokenURIs[tokenId];
        if (bytes(tokenSpecificURI).length > 0) {
            return tokenSpecificURI;
        }
        // Otherwise, concatenate the base URI and token ID.
        return string(abi.encodePacked(_baseTokenURI, _uint2str(tokenId)));
    }

    /**
     * @dev Internal helper function to convert a uint256 to a string.
     * @param _i The number to convert.
     * @return The string representation.
     */
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 temp = _i;
        uint256 length;
        while (temp != 0) {
            length++;
            temp /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        temp = _i;
        while (temp != 0) {
            k = k - 1;
            uint8 digit = uint8(temp % 10);
            bstr[k] = bytes1(48 + digit);
            temp /= 10;
        }
        return string(bstr);
    }
}
