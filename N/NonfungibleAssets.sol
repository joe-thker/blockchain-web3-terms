// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the base ERC721 so that internal functions like _exists() are available.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Import ERC721Enumerable (which itself extends ERC721).
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NonFungibleAssets
 * @notice An ERC721 token implementation representing non-fungible assets.
 *         This contract allows the owner to mint new tokens, manage token metadata,
 *         and supports token enumeration.
 */
contract NonFungibleAssets is ERC721Enumerable, Ownable {
    // Base URI for token metadata.
    string private _baseTokenURI;

    // Optional mapping for token URIs if you wish to override per-token URIs.
    mapping(uint256 => string) private _tokenURIs;

    // Counter for tracking token IDs (starting at 1).
    uint256 private _nextTokenId = 1;

    /**
     * @dev Initializes the contract by setting a name, a symbol, and a base URI.
     * @param baseURI The base URI for token metadata.
     */
    constructor(string memory baseURI) ERC721("NonFungibleAssets", "NFA") {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Mints a new token and assigns it to `to`.
     * @dev Only the contract owner may mint tokens.
     * @param to The address that will receive the minted token.
     * @return tokenId The newly minted token ID.
     */
    function mint(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId;
        _safeMint(to, tokenId);
        _nextTokenId++;
        return tokenId;
    }

    /**
     * @notice Sets the base URI for all token metadata.
     * @dev Only the contract owner can change the base URI.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Sets the token URI for a specific token.
     * @dev This function allows setting unique metadata URIs for each token.
     * @param tokenId The token ID.
     * @param _tokenURI The metadata URI for the specified token.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        require(_exists(tokenId), "NonFungibleAssets: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Returns the base URI set via {setBaseURI}. This function is automatically
     * used by {ERC721-tokenURI} to construct the final URI for each token.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Returns the URI for a given token.
     * @param tokenId The token ID.
     * @return The token URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NonFungibleAssets: URI query for nonexistent token");

        // If a specific token URI has been set, use that.
        string memory tokenSpecificURI = _tokenURIs[tokenId];
        if (bytes(tokenSpecificURI).length > 0) {
            return tokenSpecificURI;
        }
        // Otherwise, concatenate the base URI and token ID.
        return string(abi.encodePacked(_baseTokenURI, _uint2str(tokenId)));
    }

    /**
     * @dev Converts a uint256 to its decimal string representation.
     * @param _i The uint256 value to convert.
     * @return The string representation.
     */
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }
}
