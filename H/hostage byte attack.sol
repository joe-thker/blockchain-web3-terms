// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HostageByteNFT {
    mapping(uint256 => string) private _tokenURIs;

    function setHostageURI(uint256 tokenId) external {
        // Add invalid UTF-8 byte at end to trap decoders
        _tokenURIs[tokenId] = string(abi.encodePacked("https://nft.meta/", uint8(0xFF)));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return _tokenURIs[tokenId]; // May crash if off-chain decoder can't handle it
    }
}
