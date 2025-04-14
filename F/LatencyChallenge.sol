// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LatencyChallenge {
    // Stores the best latency (in seconds) submitted per user.
    mapping(address => uint256) public bestLatency;
    // Records the last ping time of a user.
    mapping(address => uint256) public lastPing;
    
    // Threshold for a winning latency (e.g., 2 seconds).
    uint256 public latencyThreshold;
    address public owner;
    
    event Ping(address indexed user, uint256 timestamp);
    event Pong(address indexed user, uint256 latency, bool isWinner);

    constructor(uint256 _threshold) {
        owner = msg.sender;
        latencyThreshold = _threshold;
    }

    /// @notice User calls ping() to record the current time.
    function ping() external {
        lastPing[msg.sender] = block.timestamp;
        emit Ping(msg.sender, block.timestamp);
    }

    /// @notice User calls pong() to measure latency and see if they win.
    function pong() external {
        uint256 pingTime = lastPing[msg.sender];
        require(pingTime != 0, "No ping recorded");
        uint256 measuredLatency = block.timestamp - pingTime;
        // Reset the ping for a new cycle.
        lastPing[msg.sender] = 0;

        bool isWinner = measuredLatency <= latencyThreshold;
        // Update best latency if this measurement is lower.
        if (isWinner && (bestLatency[msg.sender] == 0 || measuredLatency < bestLatency[msg.sender])) {
            bestLatency[msg.sender] = measuredLatency;
        }
        emit Pong(msg.sender, measuredLatency, isWinner);
    }

    /// @notice Owner can update the winning threshold.
    function setThreshold(uint256 newThreshold) external {
        require(msg.sender == owner, "Not authorized");
        latencyThreshold = newThreshold;
    }
}
