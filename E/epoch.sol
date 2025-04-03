// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title EpochManager
/// @notice This contract manages epochs defined as fixed time intervals starting from a given epochStart timestamp.
/// The current epoch is computed dynamically. The owner can update both the epoch start time and the epoch duration.
contract EpochManager is Ownable {
    /// @notice The Unix timestamp when the epoch schedule begins.
    uint256 public epochStart;
    /// @notice The duration of each epoch in seconds.
    uint256 public epochDuration;

    /// @notice Emitted when the epoch duration is updated.
    /// @param newEpochDuration The new epoch duration in seconds.
    event EpochDurationUpdated(uint256 newEpochDuration);
    /// @notice Emitted when the epoch start time is updated.
    /// @param newEpochStart The new epoch start timestamp.
    event EpochStartUpdated(uint256 newEpochStart);

    /**
     * @notice Constructor sets the initial epoch start time and duration.
     * @param _epochStart The Unix timestamp when the epoch schedule begins.
     * @param _epochDuration The duration of each epoch in seconds.
     */
    constructor(uint256 _epochStart, uint256 _epochDuration) Ownable(msg.sender) {
        require(_epochStart > 0, "Epoch start must be > 0");
        require(_epochDuration > 0, "Epoch duration must be > 0");
        epochStart = _epochStart;
        epochDuration = _epochDuration;
    }

    /**
     * @notice Returns the current epoch number based on block.timestamp.
     * @return The current epoch number. Returns 0 if block.timestamp is before epochStart.
     */
    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        // Epoch numbering starts at 1.
        return ((block.timestamp - epochStart) / epochDuration) + 1;
    }

    /**
     * @notice Updates the epoch duration.
     * @param newDuration The new duration of each epoch in seconds.
     */
    function updateEpochDuration(uint256 newDuration) external onlyOwner {
        require(newDuration > 0, "New duration must be > 0");
        epochDuration = newDuration;
        emit EpochDurationUpdated(newDuration);
    }

    /**
     * @notice Updates the epoch start time.
     * @param newStart The new epoch start time (Unix timestamp).
     */
    function updateEpochStart(uint256 newStart) external onlyOwner {
        require(newStart > 0, "New start must be > 0");
        epochStart = newStart;
        emit EpochStartUpdated(newStart);
    }
}
