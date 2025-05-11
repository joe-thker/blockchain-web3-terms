// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenizationModule - Secure Asset Tokenization & Verification

// ==============================
// 🖼️ ERC-721 Asset Tokenization (Immutable Metadata)
// ==============================
contract AssetNFT {
    string public name = "TokenizedAsset";
    string public symbol = "TASSET";

    uint256 public nextId;
    mapping(uint256 => string) public uri;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => bool) public frozen;

    event Minted(address indexed to, uint256 indexed id, string metadata);
    event Frozen(uint256 indexed id);

    function mint(address to, string memory _uri) external returns (uint256) {
        uint256 id = nextId++;
        ownerOf[id] = to;
        uri[id] = _uri;
        emit Minted(to, id, _uri);
        return id;
    }

    function freezeMetadata(uint256 id) external {
        require(msg.sender == ownerOf[id], "Not owner");
        frozen[id] = true;
        emit Frozen(id);
    }

    function updateURI(uint256 id, string memory newUri) external {
        require(msg.sender == ownerOf[id], "Not owner");
        require(!frozen[id], "Metadata frozen");
        uri[id] = newUri;
    }
}

// ==============================
// 📒 Asset Tokenization Registry
// ==============================
contract TokenizationRegistry {
    mapping(bytes32 => bool) public usedAssetHashes;

    function registerAsset(string memory description) external returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(description));
        require(!usedAssetHashes[hash], "Already tokenized");
        usedAssetHashes[hash] = true;
        return hash;
    }

    function isTokenized(string memory description) external view returns (bool) {
        return usedAssetHashes[keccak256(abi.encodePacked(description))];
    }
}

// ==============================
// 🔓 Fake Tokenization Attacker
// ==============================
interface IAssetNFT {
    function mint(address, string calldata) external returns (uint256);
}

contract FakeTokenization {
    function spoofMint(IAssetNFT nft, string calldata uri) external {
        nft.mint(msg.sender, uri); // may duplicate another asset
    }
}

// ==============================
// 🪙 Access/Utility Token (ERC20 Gated Tokenization)
// ==============================
contract AccessToken {
    string public name = "AccessToken";
    string public symbol = "ACCESS";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;

    function mint(address to, uint256 amt) external {
        balances[to] += amt;
        totalSupply += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Insufficient");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}
