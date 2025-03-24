// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CensorshipResistantMessages
/// @notice A simple decentralized message board where anyone can post messages without censorship.
/// This contract is designed to be censorship resistant by not imposing any restrictions on who can post.
contract CensorshipResistantMessages {
    // Structure to store a message.
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    // Array of all messages posted.
    Message[] public messages;

    // Event emitted when a new message is posted.
    event MessagePosted(address indexed sender, string content, uint256 timestamp);

    /// @notice Allows any user to post a message.
    /// @param _content The message content.
    function postMessage(string calldata _content) external {
        messages.push(Message({
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp
        }));
        emit MessagePosted(msg.sender, _content, block.timestamp);
    }

    /// @notice Returns the total number of messages posted.
    /// @return The count of messages.
    function getMessagesCount() external view returns (uint256) {
        return messages.length;
    }

    /// @notice Retrieves a message by its index.
    /// @param index The index of the message.
    /// @return sender The address that posted the message.
    /// @return content The content of the message.
    /// @return timestamp The timestamp when the message was posted.
    function getMessage(uint256 index) external view returns (address sender, string memory content, uint256 timestamp) {
        require(index < messages.length, "Index out of range");
        Message storage message = messages[index];
        return (message.sender, message.content, message.timestamp);
    }
}
