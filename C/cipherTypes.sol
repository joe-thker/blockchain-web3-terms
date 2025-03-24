// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title MultiCipher
/// @notice A simple contract that demonstrates two basic symmetric ciphers:
/// an XOR cipher and a Caesar cipher. These are provided for educational purposes only.
contract MultiCipher {
    
    /// @notice Performs XOR encryption or decryption on input data using a repeating key.
    /// @param data The data to be encrypted/decrypted.
    /// @param key The key used for the XOR operation.
    /// @return result The output after applying XOR with the key.
    function xorCipher(bytes memory data, bytes memory key) public pure returns (bytes memory result) {
        require(key.length > 0, "Key must not be empty");
        result = new bytes(data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // Cycle through key bytes if necessary
            result[i] = data[i] ^ key[i % key.length];
        }
    }
    
    /// @notice Encrypts data using a simple Caesar cipher (shifting each byte by 'shift' modulo 256).
    /// @param data The data to encrypt (as bytes).
    /// @param shift The number of positions to shift each byte.
    /// @return result The resulting ciphertext.
    function caesarCipher(bytes memory data, uint8 shift) public pure returns (bytes memory result) {
        result = new bytes(data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // Shift the byte and wrap around using modulo arithmetic
            result[i] = bytes1(uint8(data[i]) + shift);
        }
    }
    
    /// @notice Decrypts data that was encrypted with the Caesar cipher.
    /// @param data The ciphertext (as bytes).
    /// @param shift The number of positions that were used to shift during encryption.
    /// @return result The decrypted plaintext.
    function caesarDecipher(bytes memory data, uint8 shift) public pure returns (bytes memory result) {
        result = new bytes(data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // Reverse the shift
            result[i] = bytes1(uint8(data[i]) - shift);
        }
    }
}
