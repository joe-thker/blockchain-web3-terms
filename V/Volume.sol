// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VolumeTracker - Tracks trade volume per user and globally
contract VolumeTracker {
    address public immutable admin;
    mapping(address => uint256) public userVolume;
    mapping(uint256 => uint256) public epochVolume;
    uint256 public totalVolume;
    uint256 public immutable epochLength = 1 hours;
    uint256 public deploymentTime;

    event VolumeLogged(address indexed user, uint256 amount, uint256 epoch);

    constructor() {
        admin = msg.sender;
        deploymentTime = block.timestamp;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    /// @notice Called by external DEX/Router to log volume
    function logVolume(address user, address counterparty, uint256 amount) external onlyAdmin {
        require(user != counterparty, "Wash trade rejected");
        require(amount > 0, "Invalid amount");

        uint256 currentEpoch = (block.timestamp - deploymentTime) / epochLength;

        userVolume[user] += amount;
        epochVolume[currentEpoch] += amount;
        totalVolume += amount;

        emit VolumeLogged(user, amount, currentEpoch);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp - deploymentTime) / epochLength;
    }

    function getEpochVolume(uint256 epoch) external view returns (uint256) {
        return epochVolume[epoch];
    }

    function getUserVolume(address user) external view returns (uint256) {
        return userVolume[user];
    }

    function getTotalVolume() external view returns (uint256) {
        return totalVolume;
    }
}
