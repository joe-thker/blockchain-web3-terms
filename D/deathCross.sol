// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DeathCrossDetector
/// @notice Dynamically detects and records "Death Cross" events based on moving averages provided off-chain.
contract DeathCrossDetector is Ownable, ReentrancyGuard {
    
    // Parameters for short-term and long-term moving averages
    uint256 public shortTermPeriod;
    uint256 public longTermPeriod;

    // Struct to store Death Cross events
    struct DeathCrossEvent {
        uint256 shortTermAvg;
        uint256 longTermAvg;
        uint256 timestamp;
    }

    DeathCrossEvent[] private deathCrossEvents;

    // Events for transparency
    event ParametersUpdated(uint256 shortTermPeriod, uint256 longTermPeriod);
    event DeathCrossRecorded(uint256 indexed eventIndex, uint256 shortTermAvg, uint256 longTermAvg, uint256 timestamp);

    /// @notice Constructor sets initial moving average periods (50-day & 200-day as defaults).
    constructor(uint256 _shortTermPeriod, uint256 _longTermPeriod) Ownable(msg.sender) {
        require(_shortTermPeriod < _longTermPeriod, "Short term period must be less than long term");
        shortTermPeriod = _shortTermPeriod;
        longTermPeriod = _longTermPeriod;

        emit ParametersUpdated(shortTermPeriod, longTermPeriod);
    }

    /// @notice Owner can dynamically update moving average periods.
    function updateParameters(uint256 _shortTermPeriod, uint256 _longTermPeriod) external onlyOwner {
        require(_shortTermPeriod < _longTermPeriod, "Short term period must be less than long term");
        shortTermPeriod = _shortTermPeriod;
        longTermPeriod = _longTermPeriod;

        emit ParametersUpdated(shortTermPeriod, longTermPeriod);
    }

    /// @notice Owner submits moving average data to check and record a Death Cross event.
    /// @param prevShortTermAvg The previous short-term moving average.
    /// @param prevLongTermAvg The previous long-term moving average.
    /// @param currentShortTermAvg The current short-term moving average.
    /// @param currentLongTermAvg The current long-term moving average.
    function submitMovingAverages(
        uint256 prevShortTermAvg,
        uint256 prevLongTermAvg,
        uint256 currentShortTermAvg,
        uint256 currentLongTermAvg
    ) external onlyOwner nonReentrant {
        require(prevShortTermAvg >= prevLongTermAvg, "Previous short-term avg must be above or equal to previous long-term avg");
        require(currentShortTermAvg < currentLongTermAvg, "Current short-term avg must be below current long-term avg");

        DeathCrossEvent memory newEvent = DeathCrossEvent({
            shortTermAvg: currentShortTermAvg,
            longTermAvg: currentLongTermAvg,
            timestamp: block.timestamp
        });

        deathCrossEvents.push(newEvent);

        emit DeathCrossRecorded(deathCrossEvents.length - 1, currentShortTermAvg, currentLongTermAvg, block.timestamp);
    }

    /// @notice Returns the total number of Death Cross events recorded.
    function getDeathCrossEventCount() external view returns (uint256) {
        return deathCrossEvents.length;
    }

    /// @notice Retrieves details of a specific Death Cross event by index.
    function getDeathCrossEvent(uint256 index) external view returns (DeathCrossEvent memory) {
        require(index < deathCrossEvents.length, "Event index out of range");
        return deathCrossEvents[index];
    }
}
