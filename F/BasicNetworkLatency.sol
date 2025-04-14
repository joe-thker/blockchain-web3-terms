// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BasicNetworkLatency {
    // Stores the timestamp when a user last pings.
    mapping(address => uint256) public lastPing;
    // Stores the last recorded latency (in seconds) for each user.
    mapping(address => uint256) public lastLatency;

    event Ping(address indexed user, uint256 timestamp);
    event Pong(address indexed user, uint256 latency);

    /// @notice Record the current timestamp as a ping.
    function ping() external {
        lastPing[msg.sender] = block.timestamp;
        emit Ping(msg.sender, block.timestamp);
    }

    /// @notice Measure latency as the difference between now and the stored ping.
    function pong() external {
        uint256 pingTime = lastPing[msg.sender];
        require(pingTime != 0, "No ping recorded");
        uint256 latency = block.timestamp - pingTime;
        lastLatency[msg.sender] = latency;
        // Clear the ping value for a new cycle.
        lastPing[msg.sender] = 0;
        emit Pong(msg.sender, latency);
    }
}
