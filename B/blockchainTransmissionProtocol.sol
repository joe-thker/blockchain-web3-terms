// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockchainTransmissionProtocol
/// @notice A simplified simulation of a blockchain transmission protocol where nodes can broadcast messages.
contract BlockchainTransmissionProtocol {
    // Structure representing a message transmitted in the network.
    struct Message {
        address sender;   // The node (address) that sent the message.
        string content;   // The content of the message (e.g., transaction, block data, etc.).
        uint256 timestamp; // The time the message was broadcast.
    }
    
    // Array to store all broadcast messages.
    Message[] public messages;
    
    // Event emitted when a message is broadcast.
    event MessageBroadcast(address indexed sender, string content, uint256 timestamp);
    
    /// @notice Allows a node (user) to broadcast a message.
    /// @param content The message content to broadcast.
    function broadcastMessage(string calldata content) external {
        Message memory newMessage = Message({
            sender: msg.sender,
            content: content,
            timestamp: block.timestamp
        });
        messages.push(newMessage);
        emit MessageBroadcast(msg.sender, content, block.timestamp);
    }
    
    /// @notice Returns the total number of messages broadcast.
    /// @return count The number of messages.
    function getMessageCount() external view returns (uint256 count) {
        return messages.length;
    }
    
    /// @notice Retrieves a message by its index.
    /// @param index The index of the message in the messages array.
    /// @return sender The address that broadcast the message.
    /// @return content The content of the message.
    /// @return timestamp The timestamp when the message was broadcast.
    function getMessage(uint256 index) external view returns (address sender, string memory content, uint256 timestamp) {
        require(index < messages.length, "Index out of bounds");
        Message memory m = messages[index];
        return (m.sender, m.content, m.timestamp);
    }
}
