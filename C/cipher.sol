// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SimpleCipher
/// @notice A simple XOR-based cipher for educational purposes.
/// @dev This cipher uses a repeating key to XOR with the data. It is NOT secure for production use.
contract SimpleCipher {
    /// @notice Performs XOR encryption/decryption on the input data using the given key.
    /// @param data The data to encrypt or decrypt (in bytes).
    /// @param key The key to use for the XOR operation (in bytes).
    /// @return result The resulting encrypted or decrypted data.
    function xorCipher(bytes memory data, bytes memory key) public pure returns (bytes memory result) {
        require(key.length > 0, "Key cannot be empty");
        result = new bytes(data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // XOR each byte of data with the corresponding byte of the key (cycling through key bytes)
            result[i] = data[i] ^ key[i % key.length];
        }
    }

    /// @notice Encrypts a plaintext string using a key.
    /// @param plainText The plaintext string.
    /// @param key The key string.
    /// @return cipherText The resulting ciphertext as bytes.
    function encrypt(string memory plainText, string memory key) public pure returns (bytes memory cipherText) {
        cipherText = xorCipher(bytes(plainText), bytes(key));
    }

    /// @notice Decrypts a ciphertext (in bytes) using a key.
    /// @param cipherText The ciphertext to decrypt.
    /// @param key The key string.
    /// @return plainText The resulting plaintext string.
    function decrypt(bytes memory cipherText, string memory key) public pure returns (string memory plainText) {
        bytes memory decrypted = xorCipher(cipherText, bytes(key));
        plainText = string(decrypted);
    }
}
