// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FAVestingTracker {
    address public admin;

    struct VestingEntry {
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }

    mapping(address => VestingEntry[]) public vestingSchedule;

    event VestingAdded(address indexed recipient, uint256 amount, uint256 unlockTime);
    event TokensClaimed(address indexed user, uint256 index);

    constructor() {
        admin = msg.sender;
    }

    function addVesting(address recipient, uint256 amount, uint256 unlockTime) external {
        require(msg.sender == admin, "Only admin");
        vestingSchedule[recipient].push(VestingEntry(amount, unlockTime, false));
        emit VestingAdded(recipient, amount, unlockTime);
    }

    function claimVested(uint256 index) external {
        VestingEntry storage v = vestingSchedule[msg.sender][index];
        require(block.timestamp >= v.unlockTime, "Not unlocked yet");
        require(!v.claimed, "Already claimed");
        v.claimed = true;
        emit TokensClaimed(msg.sender, index);
        // Transfer logic omitted for demo
    }

    function getTotalUnclaimed(address user) external view returns (uint256 total) {
        VestingEntry[] memory list = vestingSchedule[user];
        for (uint256 i = 0; i < list.length; i++) {
            if (!list[i].claimed && block.timestamp >= list[i].unlockTime) {
                total += list[i].amount;
            }
        }
    }
}
