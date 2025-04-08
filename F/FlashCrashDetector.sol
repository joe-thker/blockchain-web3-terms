// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FlashCrashDetector is Ownable {
    uint256 public lastPrice;
    uint256 public lastTimestamp;
    uint256 public threshold;
    uint256 public cooldown;

    event FlashCrashDetected(uint256 oldPrice, uint256 newPrice, uint256 dropPercent, uint256 timestamp);

    constructor(uint256 _threshold, uint256 _cooldown) Ownable(msg.sender) {
        threshold = _threshold;
        cooldown = _cooldown;
    }

    function reportPrice(uint256 price) external onlyOwner {
        require(price > 0, "Invalid price");
        uint256 nowTime = block.timestamp;

        if (lastPrice > 0 && (nowTime - lastTimestamp) <= cooldown) {
            uint256 drop = lastPrice > price ? lastPrice - price : 0;
            uint256 dropPercent = (drop * 100) / lastPrice;
            if (dropPercent >= threshold) {
                emit FlashCrashDetected(lastPrice, price, dropPercent, nowTime);
            }
        }

        lastPrice = price;
        lastTimestamp = nowTime;
    }
}
