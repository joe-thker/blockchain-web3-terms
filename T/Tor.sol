// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TorRelayModule - Tor Privacy Integration with Relay Registry and Anonymous Submit

// ==============================
// 📥 Tor Drop (Anonymous Message Submission)
// ==============================
contract TorDrop {
    TorRelayRegistry public registry;
    mapping(bytes32 => bool) public seenHashes;

    event MessageReceived(address indexed relay, bytes32 indexed hash, string message);

    constructor(address _registry) {
        registry = TorRelayRegistry(_registry);
    }

    function submitMessage(string calldata msgBody) external {
        require(registry.isTrustedRelay(msg.sender), "Untrusted relay");

        bytes32 hash = keccak256(abi.encodePacked(msgBody, block.timestamp));
        require(!seenHashes[hash], "Replay blocked");

        seenHashes[hash] = true;
        emit MessageReceived(msg.sender, hash, msgBody);
    }
}

// ==============================
// 🛰️ Tor Relay Registry
// ==============================
contract TorRelayRegistry {
    mapping(address => bool) public isTrustedRelay;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function registerRelay(address relay) external {
        require(msg.sender == admin, "Only admin");
        isTrustedRelay[relay] = true;
    }

    function revokeRelay(address relay) external {
        require(msg.sender == admin, "Only admin");
        isTrustedRelay[relay] = false;
    }
}

// ==============================
// 🔓 Fake Relay (Spoof Attempt)
// ==============================
interface ITorDrop {
    function submitMessage(string calldata) external;
}

contract FakeRelay {
    function spoofSubmit(ITorDrop drop, string calldata msgBody) external {
        drop.submitMessage(msgBody); // should fail if not registered relay
    }
}
