// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlashCrashAutoPause is Pausable, Ownable {
    uint256 public lastPrice;
    uint256 public threshold;

    constructor(uint256 _threshold) Ownable(msg.sender) {
        threshold = _threshold;
    }

    function reportPrice(uint256 price) external onlyOwner {
        require(price > 0, "Invalid price");

        if (lastPrice > 0) {
            uint256 drop = lastPrice > price ? lastPrice - price : 0;
            uint256 dropPercent = (drop * 100) / lastPrice;
            if (dropPercent >= threshold) {
                _pause();
            }
        }

        lastPrice = price;
    }

    function executeTrade() external whenNotPaused {
        // trading logic goes here
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
