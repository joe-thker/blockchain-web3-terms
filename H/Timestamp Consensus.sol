contract MedianTimestampDAG {
    struct Event {
        bytes32 hash;
        uint256[] timestamps;
        uint256 consensusTimestamp;
    }

    mapping(bytes32 => Event) public events;

    function submitTimestamp(bytes32 hash, uint256 ts) external {
        events[hash].timestamps.push(ts);
        if (events[hash].timestamps.length >= 3) {
            events[hash].consensusTimestamp = computeMedian(events[hash].timestamps);
        }
    }

    function computeMedian(uint256[] memory values) internal pure returns (uint256) {
        for (uint i = 0; i < values.length; i++) {
            for (uint j = i+1; j < values.length; j++) {
                if (values[j] < values[i]) (values[i], values[j]) = (values[j], values[i]);
            }
        }
        return values[values.length / 2];
    }

    function getConsensusTimestamp(bytes32 hash) external view returns (uint256) {
        return events[hash].consensusTimestamp;
    }
}
