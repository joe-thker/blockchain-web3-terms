// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simulated Hashgraph Consensus
contract HashgraphSim {
    struct Event {
        address creator;
        uint256 timestamp;
        bytes32[] parents; // parent events (hashes)
        bytes data;
        bool finalized;
    }

    mapping(bytes32 => Event) public events;
    mapping(bytes32 => uint256) public voteCounts;

    uint256 public finalityThreshold = 3; // configurable (e.g., 3/5 nodes)

    event EventCreated(bytes32 indexed eventHash, address indexed creator);
    event EventFinalized(bytes32 indexed eventHash);

    /// @notice Create a new event (like gossip node)
    function createEvent(bytes memory data, bytes32[] memory parents) external {
        bytes32 hash = keccak256(abi.encode(msg.sender, block.timestamp, data, parents));
        require(events[hash].timestamp == 0, "Already exists");

        events[hash] = Event({
            creator: msg.sender,
            timestamp: block.timestamp,
            parents: parents,
            data: data,
            finalized: false
        });

        emit EventCreated(hash, msg.sender);
    }

    /// @notice Vote on an event as valid (simulating virtual voting)
    function voteForEvent(bytes32 eventHash) external {
        require(events[eventHash].timestamp != 0, "Event doesn't exist");
        voteCounts[eventHash]++;

        if (voteCounts[eventHash] >= finalityThreshold && !events[eventHash].finalized) {
            events[eventHash].finalized = true;
            emit EventFinalized(eventHash);
        }
    }

    function getEvent(bytes32 eventHash)
        external
        view
        returns (address creator, uint256 timestamp, bool finalized, bytes memory data)
    {
        Event memory e = events[eventHash];
        return (e.creator, e.timestamp, e.finalized, e.data);
    }
}
