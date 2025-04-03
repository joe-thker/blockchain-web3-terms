// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title EpochTypesDemo
/// @notice This contract demonstrates three different epoch mechanisms:
///         1) Fixed Epoch – determined by a fixed start time and fixed duration.
///         2) Sliding Epoch – automatically advances when the current epoch expires.
///         3) Manual Epoch – a counter that the owner can manually advance.
contract EpochTypesDemo is Ownable {
    // ------------------------------
    // Fixed Epoch
    // ------------------------------
    /// @notice The fixed epoch schedule starts at this Unix timestamp.
    uint256 public fixedEpochStart;
    /// @notice The duration (in seconds) of each fixed epoch.
    uint256 public fixedEpochDuration;

    // ------------------------------
    // Sliding Epoch
    // ------------------------------
    /// @notice The start timestamp of the current sliding epoch.
    uint256 public slidingEpochStart;
    /// @notice The duration (in seconds) of each sliding epoch.
    uint256 public slidingEpochDuration;
    /// @notice The current sliding epoch number.
    uint256 public slidingEpochCount;

    // ------------------------------
    // Manual Epoch
    // ------------------------------
    /// @notice The current manual epoch number.
    uint256 public manualEpoch;

    // ------------------------------
    // Events
    // ------------------------------
    event FixedEpochUpdated(uint256 newStart, uint256 newDuration);
    event SlidingEpochAdvanced(uint256 newEpochCount, uint256 newStart);
    event ManualEpochAdvanced(uint256 newEpoch);

    /**
     * @notice Constructor sets initial parameters for fixed and sliding epochs, and initializes the manual epoch.
     * @param _fixedStart The fixed epoch start time.
     * @param _fixedDuration The fixed epoch duration in seconds.
     * @param _slidingStart The initial sliding epoch start time.
     * @param _slidingDuration The sliding epoch duration in seconds.
     */
    constructor(
        uint256 _fixedStart,
        uint256 _fixedDuration,
        uint256 _slidingStart,
        uint256 _slidingDuration
    ) Ownable(msg.sender) {
        require(_fixedStart > 0 && _fixedDuration > 0, "Invalid fixed epoch parameters");
        require(_slidingStart > 0 && _slidingDuration > 0, "Invalid sliding epoch parameters");

        fixedEpochStart = _fixedStart;
        fixedEpochDuration = _fixedDuration;

        slidingEpochStart = _slidingStart;
        slidingEpochDuration = _slidingDuration;
        slidingEpochCount = 1; // Start counting at 1

        manualEpoch = 1;
    }

    // ------------------------------
    // Fixed Epoch Functions
    // ------------------------------

    /**
     * @notice Returns the current fixed epoch number based on fixedEpochStart and fixedEpochDuration.
     * @return The current fixed epoch number. Returns 0 if the current time is before fixedEpochStart.
     */
    function currentFixedEpoch() public view returns (uint256) {
        if (block.timestamp < fixedEpochStart) {
            return 0;
        }
        // Epoch numbering starts at 1.
        return ((block.timestamp - fixedEpochStart) / fixedEpochDuration) + 1;
    }

    /**
     * @notice Allows the owner to update the fixed epoch parameters.
     * @param newStart The new fixed epoch start time.
     * @param newDuration The new fixed epoch duration in seconds.
     */
    function updateFixedEpoch(uint256 newStart, uint256 newDuration) external onlyOwner {
        require(newStart > 0 && newDuration > 0, "Invalid parameters");
        fixedEpochStart = newStart;
        fixedEpochDuration = newDuration;
        emit FixedEpochUpdated(newStart, newDuration);
    }

    // ------------------------------
    // Sliding Epoch Functions
    // ------------------------------

    /**
     * @notice Returns the current sliding epoch number.
     * If the current time exceeds slidingEpochStart + slidingEpochDuration, the epoch is automatically advanced.
     * @return The current sliding epoch number.
     */
    function currentSlidingEpoch() public returns (uint256) {
        if (block.timestamp >= slidingEpochStart + slidingEpochDuration) {
            // Calculate how many epochs have passed
            uint256 epochsPassed = (block.timestamp - slidingEpochStart) / slidingEpochDuration;
            slidingEpochCount += epochsPassed;
            slidingEpochStart += epochsPassed * slidingEpochDuration;
            emit SlidingEpochAdvanced(slidingEpochCount, slidingEpochStart);
        }
        return slidingEpochCount;
    }

    // ------------------------------
    // Manual Epoch Functions
    // ------------------------------

    /**
     * @notice Returns the current manual epoch number.
     * @return The current manual epoch.
     */
    function currentManualEpoch() public view returns (uint256) {
        return manualEpoch;
    }

    /**
     * @notice Allows the owner to manually advance the manual epoch.
     */
    function advanceManualEpoch() external onlyOwner {
        manualEpoch += 1;
        emit ManualEpochAdvanced(manualEpoch);
    }
}
