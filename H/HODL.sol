// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HODLVault {
    address public owner;
    uint256 public unlockTime;

    event HODLStarted(address indexed user, uint256 amount, uint256 until);
    event HODLCompleted(address indexed user, uint256 amount);

    constructor(uint256 _lockDuration) payable {
        require(msg.value > 0, "No ETH sent");
        owner = msg.sender;
        unlockTime = block.timestamp + _lockDuration;
        emit HODLStarted(owner, msg.value, unlockTime);
    }

    function claim() external {
        require(msg.sender == owner, "Not owner");
        require(block.timestamp >= unlockTime, "Still HODLing");

        uint256 amount = address(this).balance;
        payable(owner).transfer(amount);
        emit HODLCompleted(owner, amount);
    }

    function getTimeLeft() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }
}
