// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimeLockedEther {
    address public owner;
    uint256 public unlockTime;

    constructor(uint256 _unlockTime) payable {
        require(_unlockTime > block.timestamp, "Unlock must be future");
        require(msg.value > 0, "Send ETH");
        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        require(block.timestamp >= unlockTime, "Too early");

        uint256 balance = address(this).balance;
        (bool sent, ) = owner.call{value: balance}("");
        require(sent, "Withdraw failed");
    }

    function getTimeLeft() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }
}
