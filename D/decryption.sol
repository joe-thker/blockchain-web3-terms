// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SimpleDecryption
/// @notice A demonstration contract that implements a simple XOR-based decryption algorithm.
/// This is for educational purposes only and is not intended for secure cryptographic operations.
contract SimpleDecryption {
    // Mapping to store encrypted data for each user.
    mapping(address => bytes) private encryptedData;

    // --- Events ---
    event DataStored(address indexed sender, bytes data);

    /// @notice Stores encrypted data for the sender.
    /// @param data The encrypted data (should be produced off-chain using an XOR cipher with a secret key).
    function storeEncryptedData(bytes calldata data) external {
        require(data.length > 0, "Data cannot be empty");
        encryptedData[msg.sender] = data;
        emit DataStored(msg.sender, data);
    }

    /// @notice Retrieves the stored encrypted data for a given user.
    /// @param user The address whose encrypted data to retrieve.
    /// @return The stored encrypted data as bytes.
    function getEncryptedData(address user) external view returns (bytes memory) {
        return encryptedData[user];
    }

    /// @notice Decrypts a ciphertext using an XOR cipher with the provided key.
    /// @param ciphertext The encrypted data.
    /// @param key The key used for XOR decryption. If the key is shorter than the ciphertext, it repeats.
    /// @return plaintext The decrypted data.
    function xorDecrypt(bytes memory ciphertext, bytes memory key) public pure returns (bytes memory plaintext) {
        require(key.length > 0, "Key cannot be empty");

        plaintext = new bytes(ciphertext.length);
        for (uint256 i = 0; i < ciphertext.length; i++) {
            // XOR each byte of the ciphertext with the corresponding byte of the key (repeating the key as necessary).
            plaintext[i] = bytes1(uint8(ciphertext[i]) ^ uint8(key[i % key.length]));
        }
    }

    /// @notice Decrypts the stored encrypted data for the sender using the provided key.
    /// @param key The key used for XOR decryption.
    /// @return The decrypted data.
    function decryptStoredData(bytes calldata key) external view returns (bytes memory) {
        bytes memory cipher = encryptedData[msg.sender];
        return xorDecrypt(cipher, key);
    }
}
