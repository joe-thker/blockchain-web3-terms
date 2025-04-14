// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LatencyLeaderboard {
    // Best (lowest) recorded latency for each user (in seconds)
    mapping(address => uint256) public bestLatency;
    
    event BestLatencyUpdated(address indexed user, uint256 latency);

    /// @notice Record a latency measurement; updates if it's better (lower) than current best.
    function recordLatency(uint256 latency) external {
        // If no latency recorded yet or the new one is lower, update it.
        if (bestLatency[msg.sender] == 0 || latency < bestLatency[msg.sender]) {
            bestLatency[msg.sender] = latency;
            emit BestLatencyUpdated(msg.sender, latency);
        }
    }

    /// @notice Retrieve the best (lowest) latency for a user.
    function getBestLatency(address user) external view returns (uint256) {
        return bestLatency[user];
    }
}
