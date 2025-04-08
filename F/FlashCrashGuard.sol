// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FlashCrashGuard
 * @dev Detects flash crashes by monitoring price inputs over time.
 */
contract FlashCrashGuard is Ownable {
    uint256 public lastPrice;
    uint256 public lastTimestamp;
    uint256 public crashThreshold; // in percentage (e.g., 20 = 20%)
    uint256 public cooldown;       // in seconds

    event PriceReported(uint256 price, uint256 timestamp);
    event FlashCrashDetected(
        uint256 previousPrice,
        uint256 newPrice,
        uint256 dropPercent,
        uint256 timestamp
    );

    /**
     * @dev Constructor sets the crash threshold and cooldown, and assigns owner.
     * @param _crashThresholdPercent Percentage drop to trigger a flash crash (e.g., 20).
     * @param _cooldownSeconds Time window in seconds to compare price drops.
     */
    constructor(uint256 _crashThresholdPercent, uint256 _cooldownSeconds)
        Ownable(msg.sender)
    {
        require(_crashThresholdPercent > 0 && _crashThresholdPercent <= 100, "Invalid threshold");
        crashThreshold = _crashThresholdPercent;
        cooldown = _cooldownSeconds;
    }

    /**
     * @notice Called by owner to report latest price.
     * @param newPrice Latest price input (e.g., from an off-chain oracle).
     */
    function reportPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Invalid price");
        uint256 currentTime = block.timestamp;

        if (lastPrice > 0 && (currentTime - lastTimestamp) <= cooldown) {
            uint256 priceDiff = lastPrice > newPrice ? (lastPrice - newPrice) : 0;
            uint256 dropPercent = (priceDiff * 100) / lastPrice;

            if (dropPercent >= crashThreshold) {
                emit FlashCrashDetected(lastPrice, newPrice, dropPercent, currentTime);
            }
        }

        lastPrice = newPrice;
        lastTimestamp = currentTime;

        emit PriceReported(newPrice, currentTime);
    }

    /**
     * @notice Update crash detection settings.
     */
    function updateSettings(uint256 _crashThresholdPercent, uint256 _cooldownSeconds) external onlyOwner {
        require(_crashThresholdPercent > 0 && _crashThresholdPercent <= 100, "Invalid threshold");
        crashThreshold = _crashThresholdPercent;
        cooldown = _cooldownSeconds;
    }

    /**
     * @notice Get last price and timestamp.
     */
    function getLastPrice() external view returns (uint256 price, uint256 timestamp) {
        return (lastPrice, lastTimestamp);
    }
}
