// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TimeLockedWallet - Unlocks funds at a specific UTC time
contract TimeLockedWallet {
    address public beneficiary;
    uint256 public unlockTime;

    constructor(address _beneficiary, uint256 _unlockTime) payable {
        require(_unlockTime > block.timestamp, "Unlock time must be in future");
        beneficiary = _beneficiary;
        unlockTime = _unlockTime;
    }

    function withdraw() external {
        require(msg.sender == beneficiary, "Not beneficiary");
        require(block.timestamp >= unlockTime, "Too early to withdraw");

        payable(beneficiary).transfer(address(this).balance);
    }

    function getTimeLeft() external view returns (uint256 secondsLeft) {
        if (block.timestamp < unlockTime) {
            return unlockTime - block.timestamp;
        }
        return 0;
    }

    receive() external payable {}
}
