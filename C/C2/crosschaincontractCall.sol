// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CrossChain
/// @notice This contract simulates a simplified cross-chain messaging system.
/// It allows users to "send" messages to a target chain (by emitting an event) and
/// "receive" messages from a source chain (stored on-chain).
contract CrossChain {
    // Mapping from a chainId (source chain) to an array of messages received from that chain.
    mapping(uint256 => string[]) private _receivedMessages;

    // Emitted when a message is sent to a target chain.
    event MessageSent(uint256 indexed targetChainId, address indexed sender, string message);

    // Emitted when a message is received from a source chain.
    event MessageReceived(uint256 indexed sourceChainId, address indexed sender, string message);

    /// @notice Sends a cross-chain message.
    /// @dev In a real system, off-chain relayers would capture this event and relay the message.
    /// @param targetChainId The identifier of the target chain.
    /// @param message The message content.
    function sendMessage(uint256 targetChainId, string calldata message) external {
        // Emit an event so off-chain systems can capture and deliver the message.
        emit MessageSent(targetChainId, msg.sender, message);
    }

    /// @notice Receives a cross-chain message from a source chain.
    /// @dev This function simulates receiving a message from another chain.
    /// In production, access might be restricted to a trusted oracle or relayer.
    /// @param sourceChainId The identifier of the source chain.
    /// @param message The message content.
    function receiveMessage(uint256 sourceChainId, string calldata message) external {
        _receivedMessages[sourceChainId].push(message);
        emit MessageReceived(sourceChainId, msg.sender, message);
    }

    /// @notice Retrieves all messages received from a specific source chain.
    /// @param sourceChainId The identifier of the source chain.
    /// @return An array of messages received from that chain.
    function getMessages(uint256 sourceChainId) external view returns (string[] memory) {
        return _receivedMessages[sourceChainId];
    }
}
