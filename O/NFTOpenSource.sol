// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTOpenSource is ERC721URIStorage, Ownable {
    uint256 private _nextId = 1;

    event ProjectMinted(uint256 indexed id, address indexed owner, string uri);
    event ProjectUpdated(uint256 indexed id, string uri);

    constructor() ERC721("OpenSourceProject","OSP") Ownable(msg.sender) {}

    /// Mint a new project NFT with metadata URI
    function mintProject(string calldata uri) external returns (uint256 id) {
        id = _nextId++;
        _safeMint(msg.sender, id);
        _setTokenURI(id, uri);
        emit ProjectMinted(id, msg.sender, uri);
    }

    /// Update metadata URI (only by NFT holder)
    function updateProjectURI(uint256 id, string calldata uri) external {
        require(ownerOf(id) == msg.sender, "Not owner");
        _setTokenURI(id, uri);
        emit ProjectUpdated(id, uri);
    }
}
