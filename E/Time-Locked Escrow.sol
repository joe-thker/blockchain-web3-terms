// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimeLockedEscrow {
    address public depositor;
    address public beneficiary;
    uint256 public releaseTime;

    constructor(address _beneficiary, uint256 _unlockTime) payable {
        require(msg.value > 0, "Send ETH");
        require(_unlockTime > block.timestamp, "Unlock must be future");
        depositor = msg.sender;
        beneficiary = _beneficiary;
        releaseTime = _unlockTime;
    }

    function release() external {
        require(block.timestamp >= releaseTime, "Too early");
        require(msg.sender == beneficiary, "Only beneficiary");
        (bool sent, ) = beneficiary.call{value: address(this).balance}("");
        require(sent, "Release failed");
    }
}
