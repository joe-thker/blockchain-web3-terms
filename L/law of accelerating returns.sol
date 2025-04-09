// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Law of Accelerating Returns – Growth Tracker
/// @notice Simulates exponential acceleration of crypto adoption/events
contract AcceleratingReturns {
    uint256 public baseValue = 10; // Initial users
    uint256 public growthFactor = 105; // 5% growth rate per unit
    uint256 public lastTimestamp;
    uint256 public users;

    event GrowthUpdated(uint256 newUserCount, uint256 timeElapsed);

    constructor() {
        users = baseValue;
        lastTimestamp = block.timestamp;
    }

    function simulateGrowth() external {
        uint256 elapsed = block.timestamp - lastTimestamp;
        require(elapsed > 0, "Wait for time to pass");

        for (uint256 i = 0; i < elapsed; i++) {
            users = (users * growthFactor) / 100;
        }

        lastTimestamp = block.timestamp;
        emit GrowthUpdated(users, elapsed);
    }

    function getUsers() external view returns (uint256) {
        return users;
    }
}
