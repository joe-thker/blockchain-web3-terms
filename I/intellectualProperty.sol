// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title IntellectualPropertyNFT
/// @notice Tokenizes IP assets with metadata and optional licenses.
contract IntellectualPropertyNFT is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;

    // Maps tokenId => licensee address
    mapping(uint256 => address) public licensee;

    event IPMinted(address indexed owner, uint256 tokenId, string ipfsMetadata);
    event LicenseGranted(uint256 tokenId, address licensee);

    constructor() ERC721("IntellectualPropertyNFT", "IPNFT") Ownable(msg.sender) {}

    /// @notice Mint an IP NFT with metadata (e.g., IPFS CID of legal doc)
    function mintIP(string memory tokenURI) external returns (uint256) {
        uint256 tokenId = ++tokenCounter;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        emit IPMinted(msg.sender, tokenId, tokenURI);
        return tokenId;
    }

    /// @notice Assign license rights to another address
    function assignLicense(uint256 tokenId, address _licensee) external {
        require(ownerOf(tokenId) == msg.sender, "Not IP owner");
        licensee[tokenId] = _licensee;
        emit LicenseGranted(tokenId, _licensee);
    }

    /// @notice View the current licensee of a token
    function viewLicensee(uint256 tokenId) external view returns (address) {
        return licensee[tokenId];
    }
}
