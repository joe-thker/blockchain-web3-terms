// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HostageMetadata {
    mapping(uint256 => string) public tokenURIs;

    function setMaliciousURI(uint256 tokenId) external {
        // Add invalid UTF-8 byte at the end (0xFF)
        tokenURIs[tokenId] = string(abi.encodePacked("https://meta.io/bad", bytes1(0xFF)));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return tokenURIs[tokenId];
    }
}
