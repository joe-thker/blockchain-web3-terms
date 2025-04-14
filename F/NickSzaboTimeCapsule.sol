// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NickSzaboTimeCapsule
/// @notice A time-locked vault that holds funds until a specified unlock timestamp.
contract NickSzaboTimeCapsule {
    address public owner;
    uint256 public unlockTime;

    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed receiver, uint256 amount);

    /// @notice Constructor sets the unlock time.
    /// @param _unlockTime Timestamp when the funds can be withdrawn.
    constructor(uint256 _unlockTime) {
        require(_unlockTime > block.timestamp, "Unlock time must be in the future");
        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    /// @notice Deposit funds into the capsule.
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw funds after unlock time. Only the owner can withdraw.
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(block.timestamp >= unlockTime, "Funds are locked");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner).transfer(balance);
        emit Withdrawn(owner, balance);
    }
}
