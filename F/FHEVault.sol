// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FHE Encrypted Data Vault
/// @notice Users can store encrypted messages/data off-chain and use tags to describe operations.

contract FHEVault {
    address public owner;

    struct Ciphertext {
        bytes32 encrypted; // Assume FHE ciphertext (simulated)
        string description; // e.g., "encrypted vote", "FHE: a + b"
    }

    mapping(address => Ciphertext[]) public userVault;

    event DataStored(address indexed user, uint256 index, string description);
    event DataRetrieved(address indexed user, uint256 index, bytes32 cipher);

    constructor() {
        owner = msg.sender;
    }

    function storeEncryptedData(bytes32 cipher, string memory description) external {
        userVault[msg.sender].push(Ciphertext(cipher, description));
        emit DataStored(msg.sender, userVault[msg.sender].length - 1, description);
    }

    function getEncryptedData(uint256 index) external view returns (bytes32, string memory) {
        Ciphertext memory data = userVault[msg.sender][index];
        return (data.encrypted, data.description);
    }

    function getVaultLength(address user) external view returns (uint256) {
        return userVault[user].length;
    }
}
