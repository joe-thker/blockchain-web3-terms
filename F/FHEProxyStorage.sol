// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simulated Fully Homomorphic Encrypted Data Proxy
/// @notice Accepts encrypted data and operations from off-chain FHE computation

contract FHEProxyStorage {
    address public owner;

    struct EncryptedData {
        bytes32 cipher; // encrypted with FHE off-chain
        string tag;     // e.g., "FHE:sum:x+y"
    }

    mapping(address => EncryptedData[]) public userEncryptedData;

    event EncryptedDataStored(address indexed user, string tag, bytes32 cipher);
    event DecryptionRequested(address indexed user, uint256 index);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function storeEncrypted(bytes32 cipher, string calldata tag) external {
        userEncryptedData[msg.sender].push(EncryptedData(cipher, tag));
        emit EncryptedDataStored(msg.sender, tag, cipher);
    }

    function getEncrypted(address user, uint256 index) external view returns (bytes32, string memory) {
        EncryptedData memory data = userEncryptedData[user][index];
        return (data.cipher, data.tag);
    }

    /// Optional: emit an event to request off-chain decryption by owner
    function requestDecryption(uint256 index) external {
        require(index < userEncryptedData[msg.sender].length, "Invalid index");
        emit DecryptionRequested(msg.sender, index);
    }

    function getEncryptedCount(address user) external view returns (uint256) {
        return userEncryptedData[user].length;
    }
}
