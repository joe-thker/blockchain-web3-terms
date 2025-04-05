// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GossipDAG {
    struct Event {
        bytes32 hash;
        address creator;
        bytes32[] parents;
        uint256 timestamp;
        bytes data;
    }

    mapping(bytes32 => Event) public events;
    bytes32[] public eventList;

    event EventCreated(bytes32 indexed eventHash, address indexed creator);

    function createEvent(bytes memory data, bytes32[] memory parents) external {
        bytes32 hash = keccak256(abi.encode(msg.sender, block.timestamp, data, parents));
        events[hash] = Event(hash, msg.sender, parents, block.timestamp, data);
        eventList.push(hash);
        emit EventCreated(hash, msg.sender);
    }

    function getParents(bytes32 eventHash) external view returns (bytes32[] memory) {
        return events[eventHash].parents;
    }
}
