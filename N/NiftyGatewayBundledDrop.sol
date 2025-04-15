// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NiftyGatewayBundledDrop is ERC721Enumerable, Ownable {
    uint256 public nextTokenId;
    uint256 public bundleSize;
    uint256 public bundleStart;
    bool public dropActive;
    string public baseURI;

    event BundleLaunched(uint256 bundleSize, uint256 bundleStart);
    event NFTClaimed(address indexed buyer, uint256 tokenId);

    constructor(address initialOwner)
        ERC721("NiftyGateway Bundled Drop", "NGBD")
        Ownable(initialOwner)
    {}

    /// @notice Launch a new bundled drop by minting a batch of NFTs.
    /// @param _bundleSize The number of NFTs in this bundle.
    /// @param _baseURI The base URI to use for NFTs.
    function launchBundle(uint256 _bundleSize, string calldata _baseURI) external onlyOwner {
        require(!dropActive, "Bundle already active");
        bundleSize = _bundleSize;
        bundleStart = nextTokenId;
        baseURI = _baseURI;
        for (uint256 i = 0; i < _bundleSize; i++) {
            uint256 tokenId = nextTokenId;
            _mint(address(this), tokenId);
            nextTokenId++;
        }
        dropActive = true;
        emit BundleLaunched(bundleSize, bundleStart);
    }

    /// @notice Claim a random NFT from the bundled drop.
    function claimNFT() external {
        require(dropActive, "No active bundle");
        uint256 supply = balanceOf(address(this));
        require(supply > 0, "No NFTs left to claim");
        uint256 randIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % supply;
        uint256 tokenId = tokenOfOwnerByIndex(address(this), randIndex);
        _transfer(address(this), msg.sender, tokenId);
        emit NFTClaimed(msg.sender, tokenId);
    }

    /// @notice End the current drop bundle.
    function endBundle() external onlyOwner {
        dropActive = false;
    }

    /// @notice Override tokenURI to build the full URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, uint2str(tokenId)));
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while(j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k--;
            uint8 temp = uint8(48 + _i % 10);
            bstr[k] = bytes1(temp);
            _i /= 10;
        }
        return string(bstr);
    }
}
