// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Higher High Pattern Detector
contract HigherHighTracker {
    address public owner;

    uint256 public lastHigh;
    uint256 public prevHigh;
    uint256 public lastLow;

    event NewHigh(uint256 newHigh);
    event HigherHighConfirmed(uint256 current, uint256 previous);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(uint256 _initialHigh) {
        owner = msg.sender;
        lastHigh = _initialHigh;
    }

    function recordHigh(uint256 newHigh) external onlyOwner {
        require(newHigh > 0, "Invalid high");

        if (newHigh > lastHigh) {
            emit HigherHighConfirmed(newHigh, lastHigh);
            prevHigh = lastHigh;
            lastHigh = newHigh;
        } else {
            prevHigh = lastHigh;
            lastHigh = newHigh;
        }

        emit NewHigh(newHigh);
    }

    function getHighs() external view returns (uint256 previous, uint256 current) {
        return (prevHigh, lastHigh);
    }
}
