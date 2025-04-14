// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NetworkLatency
/// @notice This contract simulates network latency measurement by recording a "ping" timestamp
///         and then calculating the latency when the user calls "pong()".
contract NetworkLatency {
    // Stores the timestamp of the last ping for each sender.
    mapping(address => uint256) public lastPingTimestamp;
    // Sum of all latencies measured for each user.
    mapping(address => uint256) public totalLatency;
    // Number of ping–pong cycles per user.
    mapping(address => uint256) public pingCount;

    // Events for logging ping and pong.
    event Ping(address indexed sender, uint256 timestamp);
    event Pong(address indexed sender, uint256 latency, uint256 averageLatency);

    /// @notice Called by a user to record a "ping".
    function ping() external {
        // Record the current block timestamp as ping time.
        lastPingTimestamp[msg.sender] = block.timestamp;
        emit Ping(msg.sender, block.timestamp);
    }

    /// @notice Called by a user after ping to calculate latency.
    /// @dev Computes the difference between the current time and the stored ping timestamp.
    function pong() external {
        require(lastPingTimestamp[msg.sender] != 0, "No ping recorded");

        // Calculate latency as the difference between now and the stored ping timestamp.
        uint256 latency = block.timestamp - lastPingTimestamp[msg.sender];

        // Reset the ping for this user.
        lastPingTimestamp[msg.sender] = 0;

        // Update the total latency and the count of pings.
        totalLatency[msg.sender] += latency;
        pingCount[msg.sender] += 1;
        uint256 averageLatency = totalLatency[msg.sender] / pingCount[msg.sender];

        emit Pong(msg.sender, latency, averageLatency);
    }

    /// @notice Get the current average latency for a user.
    /// @param user The address of the user.
    function getAverageLatency(address user) external view returns (uint256) {
        if (pingCount[user] == 0) return 0;
        return totalLatency[user] / pingCount[user];
    }
}
