// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GeotaggedNFT is ERC721URIStorage, Ownable {
    uint256 public nextId;

    struct GeoTag {
        int256 latitude;    // e.g., 37420000 = 37.420000°
        int256 longitude;   // e.g., -122084000 = -122.084000°
    }

    mapping(uint256 => GeoTag) public geoTags;

    event GeoNFTMinted(uint256 indexed tokenId, address indexed to, int256 lat, int256 long);

    constructor() ERC721("GeoNFT", "GNFT") Ownable(msg.sender) {}

    /// @notice Mint a geotagged NFT
    /// @param to Receiver of the NFT
    /// @param latitude Latitude in millionths (e.g., 37420000 for 37.42°)
    /// @param longitude Longitude in millionths (e.g., -122084000 for -122.084°)
    /// @param uri Metadata URI (e.g., IPFS link)
    function mint(
        address to,
        int256 latitude,
        int256 longitude,
        string memory uri
    ) external onlyOwner {
        require(latitude >= -90000000 && latitude <= 90000000, "Invalid latitude");
        require(longitude >= -180000000 && longitude <= 180000000, "Invalid longitude");

        uint256 tokenId = nextId++;
        geoTags[tokenId] = GeoTag(latitude, longitude);
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit GeoNFTMinted(tokenId, to, latitude, longitude);
    }

    /// @notice Get geolocation of NFT
    function getGeo(uint256 tokenId) external view returns (int256, int256) {
        GeoTag memory g = geoTags[tokenId];
        return (g.latitude, g.longitude);
    }
}
