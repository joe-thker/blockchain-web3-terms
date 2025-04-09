// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Lachesis DAG Event Commit Simulator
contract LachesisCommit {
    struct EventBlock {
        address creator;
        bytes32 hash;
        uint256 timestamp;
        bytes32[] parents; // references to parent events
    }

    mapping(bytes32 => EventBlock) public events;
    mapping(address => bytes32[]) public creatorEvents;

    event EventCommitted(address indexed creator, bytes32 hash);

    function commitEvent(bytes32 hash, bytes32[] calldata parents) external {
        require(events[hash].timestamp == 0, "Event already exists");

        events[hash] = EventBlock({
            creator: msg.sender,
            hash: hash,
            timestamp: block.timestamp,
            parents: parents
        });

        creatorEvents[msg.sender].push(hash);

        emit EventCommitted(msg.sender, hash);
    }

    function getCreatorEvents(address creator) external view returns (bytes32[] memory) {
        return creatorEvents[creator];
    }
}
