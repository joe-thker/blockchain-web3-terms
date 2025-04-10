// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract LowerLowDetector {
    uint256 public previousLow;
    uint256 public currentLow;
    bool public isLowerLow;

    event NewLow(uint256 value, bool isLowerLow);

    function updateLow(uint256 newLow) external {
        if (currentLow != 0) {
            previousLow = currentLow;
        }
        currentLow = newLow;

        isLowerLow = (previousLow > 0 && newLow < previousLow);
        emit NewLow(newLow, isLowerLow);
    }
}
