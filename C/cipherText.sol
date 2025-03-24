// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CipherTextStore
/// @notice A contract to encrypt, store, and decrypt messages using a simple XOR cipher.
/// @dev This example is for educational purposes and does not provide strong security.
contract CipherTextStore {
    address public owner;
    uint256 public nextMessageId;

    // Structure to store an encrypted message.
    struct EncryptedMessage {
        bytes cipherText;   // The encrypted data.
        uint256 timestamp;  // When the message was stored.
        address sender;     // Who stored the message.
    }
    
    // Mapping from message ID to its encrypted message.
    mapping(uint256 => EncryptedMessage) public messages;

    event MessageStored(uint256 indexed messageId, address indexed sender, uint256 timestamp, bytes cipherText);

    constructor() {
        owner = msg.sender;
        nextMessageId = 0;
    }

    /// @notice Performs XOR encryption/decryption on the input data using the provided key.
    /// @param data The data to encrypt or decrypt.
    /// @param key The key used for the XOR operation.
    /// @return result The output after applying XOR.
    function xorCipher(bytes memory data, bytes memory key) public pure returns (bytes memory result) {
        require(key.length > 0, "Key cannot be empty");
        result = new bytes(data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // Apply XOR with the corresponding key byte (cycling through key bytes).
            result[i] = data[i] ^ key[i % key.length];
        }
    }

    /// @notice Encrypts a plain text message with a key and stores the resulting cipher text on-chain.
    /// @param plainText The message to encrypt.
    /// @param key The key used for encryption.
    /// @return messageId The ID assigned to the stored encrypted message.
    function encryptAndStore(string memory plainText, string memory key) external returns (uint256 messageId) {
        bytes memory plainBytes = bytes(plainText);
        bytes memory keyBytes = bytes(key);
        bytes memory cipher = xorCipher(plainBytes, keyBytes);

        messageId = nextMessageId;
        messages[messageId] = EncryptedMessage({
            cipherText: cipher,
            timestamp: block.timestamp,
            sender: msg.sender
        });
        nextMessageId++;

        emit MessageStored(messageId, msg.sender, block.timestamp, cipher);
    }

    /// @notice Retrieves the cipher text for a stored message.
    /// @param messageId The ID of the stored message.
    /// @return The cipher text as bytes.
    function getCipherText(uint256 messageId) external view returns (bytes memory) {
        require(messageId < nextMessageId, "Invalid message ID");
        return messages[messageId].cipherText;
    }

    /// @notice Decrypts a stored cipher text using the provided key.
    /// @param messageId The ID of the stored message.
    /// @param key The key used for decryption.
    /// @return The decrypted plain text string.
    function decryptStored(uint256 messageId, string memory key) external view returns (string memory) {
        require(messageId < nextMessageId, "Invalid message ID");
        EncryptedMessage storage em = messages[messageId];
        bytes memory decrypted = xorCipher(em.cipherText, bytes(key));
        return string(decrypted);
    }
}
