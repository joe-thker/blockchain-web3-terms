// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract LowerHighDetector {
    uint256 public previousHigh;
    uint256 public lastHigh;
    bool public isLowerHigh;

    event NewHigh(uint256 value, bool isLowerHigh);

    function updateHigh(uint256 newHigh) external {
        if (lastHigh != 0) {
            previousHigh = lastHigh;
        }
        lastHigh = newHigh;

        if (previousHigh > 0 && newHigh < previousHigh) {
            isLowerHigh = true;
        } else {
            isLowerHigh = false;
        }

        emit NewHigh(newHigh, isLowerHigh);
    }
}
