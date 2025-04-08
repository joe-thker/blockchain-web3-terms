// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// 1. Copyright NFT (e.g., music, artwork)
contract CopyrightNFT is ERC721URIStorage, Ownable {
    uint256 public tokenId;
    constructor() ERC721("CopyrightNFT", "COPY") Ownable(msg.sender) {}
    function mint(string calldata uri) external returns (uint256) {
        uint256 newId = ++tokenId;
        _mint(msg.sender, newId);
        _setTokenURI(newId, uri);
        return newId;
    }
}

/// 2. Trademark NFT (e.g., brand/logo claims)
contract TrademarkNFT is ERC721URIStorage, Ownable {
    uint256 public tokenId;
    constructor() ERC721("TrademarkNFT", "TMK") Ownable(msg.sender) {}
    function registerTrademark(string calldata uri) external returns (uint256) {
        uint256 newId = ++tokenId;
        _mint(msg.sender, newId);
        _setTokenURI(newId, uri);
        return newId;
    }
}

/// 3. Patent NFT (e.g., technical methods)
contract PatentNFT is ERC721URIStorage, Ownable {
    uint256 public tokenId;
    constructor() ERC721("PatentNFT", "PAT") Ownable(msg.sender) {}
    function filePatent(string calldata uri) external returns (uint256) {
        uint256 newId = ++tokenId;
        _mint(msg.sender, newId);
        _setTokenURI(newId, uri);
        return newId;
    }
}

/// 4. Trade Secret Token (non-transferable proof only)
contract TradeSecretProof is Ownable {
    struct SecretHash {
        bytes32 hash;
        uint256 timestamp;
    }
    mapping(address => SecretHash[]) public userProofs;

    event SecretFiled(address indexed user, bytes32 hash, uint256 timestamp);

    constructor() Ownable(msg.sender) {}

    function fileSecret(string calldata secret) external {
        bytes32 hash = keccak256(abi.encodePacked(secret));
        userProofs[msg.sender].push(SecretHash(hash, block.timestamp));
        emit SecretFiled(msg.sender, hash, block.timestamp);
    }

    function getProofs(address user) external view returns (SecretHash[] memory) {
        return userProofs[user];
    }
}

/// 5. IP License Token (grants use rights, not ownership)
contract IPLicenseNFT is ERC721URIStorage, Ownable {
    uint256 public tokenId;
    mapping(uint256 => address) public licensee;

    constructor() ERC721("IPLicenseNFT", "LIC") Ownable(msg.sender) {}

    function mintWithLicense(string calldata uri, address _licensee) external returns (uint256) {
        uint256 newId = ++tokenId;
        _mint(msg.sender, newId);
        _setTokenURI(newId, uri);
        licensee[newId] = _licensee;
        return newId;
    }

    function getLicensee(uint256 id) external view returns (address) {
        return licensee[id];
    }
}
