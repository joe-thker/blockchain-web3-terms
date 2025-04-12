// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FAActivityScore {
    address public admin;

    uint256 public interactionWindow = 30 days;
    mapping(address => uint256) public lastActivity;
    uint256 public activeUserCount;

    constructor() {
        admin = msg.sender;
    }

    function recordActivity(address user) external {
        if (block.timestamp - lastActivity[user] > interactionWindow) {
            activeUserCount++;
        }
        lastActivity[user] = block.timestamp;
    }

    function getActivityScore() external view returns (uint256) {
        return activeUserCount;
    }
}
