// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title InterChainReceiver
/// @notice Simulates receiving messages from other chains with relayer verification
contract InterChainReceiver {
    address public trustedRelayer;
    mapping(bytes32 => bool) public processedMessages;

    event MessageReceived(address indexed fromChain, string payload, bytes32 messageId);

    constructor(address _trustedRelayer) {
        trustedRelayer = _trustedRelayer;
    }

    /// @notice Receive message sent from another chain
    /// @param fromChain The address or name of the source chain
    /// @param payload The content/message/data sent
    /// @param messageId Unique identifier (to prevent replay)
    function receiveCrossChainMessage(
        address fromChain,
        string calldata payload,
        bytes32 messageId
    ) external {
        require(msg.sender == trustedRelayer, "Not authorized relayer");
        require(!processedMessages[messageId], "Already processed");

        processedMessages[messageId] = true;

        // Handle the message (could trigger logic)
        emit MessageReceived(fromChain, payload, messageId);
    }
}
