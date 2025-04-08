// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FlashCrashSimulator {
    uint256 public simulatedPrice = 1000;
    bool public crashed = false;

    event PriceSimulated(uint256 oldPrice, uint256 newPrice, bool crashed);

    function simulateCrash(uint256 dropPercent) external {
        require(dropPercent > 0 && dropPercent <= 100, "Invalid drop");
        uint256 oldPrice = simulatedPrice;
        simulatedPrice = simulatedPrice - (simulatedPrice * dropPercent / 100);
        crashed = true;
        emit PriceSimulated(oldPrice, simulatedPrice, true);
    }

    function resetPrice(uint256 newPrice) external {
        simulatedPrice = newPrice;
        crashed = false;
    }
}
