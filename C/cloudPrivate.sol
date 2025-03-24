// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title PrivateCloud
/// @notice A simple contract simulating a private cloud where only the owner can store data.
contract PrivateCloud {
    address public owner;
    string private message;

    event MessageStored(string newMessage);

    constructor() {
        owner = msg.sender;
    }

    /// @notice Stores a message. Only the owner can call this.
    /// @param _message The message to store.
    function storeMessage(string calldata _message) external {
        require(msg.sender == owner, "Only owner can store message");
        message = _message;
        emit MessageStored(_message);
    }

    /// @notice Retrieves the stored message.
    /// @return The current message.
    function getMessage() external view returns (string memory) {
        return message;
    }
}
