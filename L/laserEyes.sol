// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Laser Eyes Soulbound Badge
/// @notice Soulbound NFT badge for laser-eyed believers

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract LaserEyesBadge is ERC721, ERC721URIStorage {
    uint256 public tokenIdCounter;
    mapping(address => bool) public hasLaserEyes;

    constructor() ERC721("LaserEyesBadge", "LASER") {}

    function mintLaserEyes(string calldata metadataURI) external {
        require(!hasLaserEyes[msg.sender], "Already lasered");
        tokenIdCounter++;
        uint256 newTokenId = tokenIdCounter;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, metadataURI);
        hasLaserEyes[msg.sender] = true;
    }

    // 🛡️ Soulbound logic – block all transfers (no sending or receiving)
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        require(from == address(0) || to == address(0), "Soulbound - no transfers allowed");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // 🖼 Metadata support
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // 📡 Interface support resolver
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ❌ No token burning needed, skip _burn override
}
