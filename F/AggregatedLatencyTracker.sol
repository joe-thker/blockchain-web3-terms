// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AggregatedLatencyTracker {
    // For each user, store an array of latency measurements (in seconds)
    mapping(address => uint256[]) public latencies;

    event LatencyRecorded(address indexed user, uint256 latency);

    /// @notice Record a latency measurement for the sender.
    function recordLatency(uint256 latency) external {
        latencies[msg.sender].push(latency);
        emit LatencyRecorded(msg.sender, latency);
    }

    /// @notice Calculate the average latency for a given user.
    function getAverageLatency(address user) external view returns (uint256) {
        uint256[] storage measurements = latencies[user];
        uint256 total;
        for (uint256 i = 0; i < measurements.length; i++) {
            total += measurements[i];
        }
        return measurements.length > 0 ? total / measurements.length : 0;
    }
}
