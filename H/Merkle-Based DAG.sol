contract MerkleDAG {
    struct Event {
        bytes32 hash;
        bytes32[] parents;
    }

    mapping(bytes32 => Event) public events;

    function createMerkleEvent(bytes32[] memory parents) external returns (bytes32) {
        bytes32 combined = keccak256(abi.encodePacked(parents));
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, block.timestamp, combined));
        events[hash] = Event(hash, parents);
        return hash;
    }

    function verifyEvent(bytes32 hash) external view returns (bool) {
        return events[hash].hash == hash;
    }
}
