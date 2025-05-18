// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WatcherRelay {
    address public admin;
    mapping(address => bool) public isAuthorizedWatcher;
    mapping(bytes32 => bool) public executedMessages;

    event MessageExecuted(bytes32 indexed msgId, address indexed watcher, address target, bytes payload);

    modifier onlyWatcher() {
        require(isAuthorizedWatcher[msg.sender], "Not authorized watcher");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function addWatcher(address watcher) external {
        require(msg.sender == admin, "Only admin");
        isAuthorizedWatcher[watcher] = true;
    }

    function relayMessage(bytes32 msgId, address target, bytes calldata payload) external onlyWatcher {
        require(!executedMessages[msgId], "Message already executed");

        executedMessages[msgId] = true;
        (bool success, ) = target.call(payload);
        require(success, "Relay failed");

        emit MessageExecuted(msgId, msg.sender, target, payload);
    }

    function hasExecuted(bytes32 msgId) external view returns (bool) {
        return executedMessages[msgId];
    }
}
