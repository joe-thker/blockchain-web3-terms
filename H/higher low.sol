// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Higher Low Detector
contract HigherLowTracker {
    address public owner;

    uint256 public lastLow;
    uint256 public prevLow;

    event NewLow(uint256 newLow);
    event HigherLowConfirmed(uint256 newLow, uint256 previousLow);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(uint256 _initialLow) {
        owner = msg.sender;
        lastLow = _initialLow;
    }

    /// @notice Feed a new low and check if it qualifies as a higher low
    function recordLow(uint256 newLow) external onlyOwner {
        require(newLow > 0, "Low must be positive");

        if (newLow > lastLow) {
            emit HigherLowConfirmed(newLow, lastLow);
            prevLow = lastLow;
            lastLow = newLow;
        } else {
            prevLow = lastLow;
            lastLow = newLow;
        }

        emit NewLow(newLow);
    }

    function getLows() external view returns (uint256 previous, uint256 current) {
        return (prevLow, lastLow);
    }
}
