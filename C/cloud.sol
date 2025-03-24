// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title PublicCloud
/// @notice A simple contract simulating a public cloud where anyone can store and retrieve a message.
contract PublicCloud {
    string private message;

    event MessageStored(string newMessage);

    /// @notice Stores a message. Anyone can call this.
    /// @param _message The message to store.
    function storeMessage(string calldata _message) external {
        message = _message;
        emit MessageStored(_message);
    }

    /// @notice Retrieves the stored message.
    /// @return The current message.
    function getMessage() external view returns (string memory) {
        return message;
    }
}
