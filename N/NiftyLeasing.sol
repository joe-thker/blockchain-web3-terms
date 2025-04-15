// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NiftyGatewayLeasing
/// @notice NFT contract that supports leasing; owners can lease their NFTs to tenants.
contract NiftyGatewayLeasing is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;

    struct Lease {
        address tenant;
        uint256 leaseExpiry;
    }
    mapping(uint256 => Lease) public leases;

    event NFTMinted(address indexed to, uint256 tokenId, string tokenURI);
    event NFTLeased(uint256 tokenId, address indexed tenant, uint256 leaseExpiry);
    event NFTLeaseCanceled(uint256 tokenId);

    constructor(address initialOwner) ERC721("NiftyGateway Leasing", "NGLEASE") Ownable(initialOwner) {}

    /// @notice Mint a new NFT.
    function mintNFT(address to, string calldata tokenURI) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        nextTokenId++;
        emit NFTMinted(to, tokenId, tokenURI);
    }

    /// @notice Lease an NFT to a tenant for a given duration (in seconds).
    function leaseNFT(uint256 tokenId, address tenant, uint256 leaseDuration) external {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(tenant != address(0), "Invalid tenant address");
        leases[tokenId] = Lease(tenant, block.timestamp + leaseDuration);
        emit NFTLeased(tokenId, tenant, block.timestamp + leaseDuration);
    }

    /// @notice Cancel an active lease. Only the NFT owner can cancel.
    function cancelLease(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner");
        delete leases[tokenId];
        emit NFTLeaseCanceled(tokenId);
    }
}
