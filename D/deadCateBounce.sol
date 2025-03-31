// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DeadCatBounceDetector
/// @notice Contract dynamically identifies and records "Dead Cat Bounce" events based on configurable criteria.
/// Only the owner (admin) can update the parameters and submit price data.
contract DeadCatBounceDetector is Ownable, ReentrancyGuard {

    /// @notice Struct to store bounce event details.
    struct BounceEvent {
        uint256 initialDeclinePrice;
        uint256 bouncePrice;
        uint256 finalDeclinePrice;
        uint256 timestamp;
    }

    // Dynamic configurable parameters:
    uint256 public declineThreshold;  // Percentage of decline (e.g., 20% = 2000, scaled by 10000)
    uint256 public bounceThreshold;   // Percentage of bounce recovery (e.g., 5% = 500, scaled by 10000)

    // Array of recorded bounce events:
    BounceEvent[] public bounceEvents;

    // Events for transparency:
    event ParametersUpdated(uint256 declineThreshold, uint256 bounceThreshold);
    event BounceRecorded(uint256 indexed index, uint256 initialDeclinePrice, uint256 bouncePrice, uint256 finalDeclinePrice);

    /// @notice Constructor initializes parameters (example defaults: 20% decline, 5% bounce)
    constructor(uint256 _declineThreshold, uint256 _bounceThreshold) Ownable(msg.sender) {
        require(_declineThreshold > 0 && _bounceThreshold > 0, "Thresholds must be greater than 0");
        declineThreshold = _declineThreshold;
        bounceThreshold = _bounceThreshold;
        emit ParametersUpdated(declineThreshold, bounceThreshold);
    }

    /// @notice Owner updates parameters dynamically.
    function updateParameters(uint256 _declineThreshold, uint256 _bounceThreshold) external onlyOwner {
        require(_declineThreshold > 0 && _bounceThreshold > 0, "Thresholds must be greater than 0");
        declineThreshold = _declineThreshold;
        bounceThreshold = _bounceThreshold;
        emit ParametersUpdated(declineThreshold, bounceThreshold);
    }

    /// @notice Owner submits price points to validate and record a bounce event.
    /// @param initialDeclinePrice - Price at start of decline.
    /// @param lowestPrice - Lowest price after decline.
    /// @param bouncePrice - Price after bounce occurs.
    /// @param finalDeclinePrice - Price after bounce ends and decline resumes.
    function submitBounceEvent(
        uint256 initialDeclinePrice,
        uint256 lowestPrice,
        uint256 bouncePrice,
        uint256 finalDeclinePrice
    ) external onlyOwner nonReentrant {
        require(
            initialDeclinePrice > lowestPrice &&
            bouncePrice > lowestPrice &&
            bouncePrice < initialDeclinePrice &&
            finalDeclinePrice < bouncePrice,
            "Prices do not reflect a valid Dead Cat Bounce"
        );

        uint256 declinePercent = ((initialDeclinePrice - lowestPrice) * 10000) / initialDeclinePrice;
        uint256 bouncePercent = ((bouncePrice - lowestPrice) * 10000) / initialDeclinePrice;

        require(declinePercent >= declineThreshold, "Initial decline not sufficient");
        require(bouncePercent >= bounceThreshold, "Bounce not sufficient");

        BounceEvent memory newEvent = BounceEvent({
            initialDeclinePrice: initialDeclinePrice,
            bouncePrice: bouncePrice,
            finalDeclinePrice: finalDeclinePrice,
            timestamp: block.timestamp
        });

        bounceEvents.push(newEvent);
        emit BounceRecorded(bounceEvents.length - 1, initialDeclinePrice, bouncePrice, finalDeclinePrice);
    }

    /// @notice Returns the number of recorded bounce events.
    function getBounceEventCount() external view returns (uint256) {
        return bounceEvents.length;
    }

    /// @notice Retrieves a specific bounce event by index.
    function getBounceEvent(uint256 index) external view returns (BounceEvent memory) {
        require(index < bounceEvents.length, "Event index out of range");
        return bounceEvents[index];
    }
}
