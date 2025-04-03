// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ElliottWaves
/// @notice A dynamic contract for recording Elliott wave analysis data.
/// Each wave includes a sequence number, start and end timestamps, start and end prices,
/// a flag indicating whether it is an impulse (trend) or corrective wave, and an active flag.
contract ElliottWaves is Ownable {
    /// @notice Structure representing an Elliott wave.
    struct Wave {
        uint256 waveNumber; // Sequential number of the wave
        uint256 startTime;  // Timestamp when the wave started
        uint256 endTime;    // Timestamp when the wave ended (0 if ongoing)
        int256 startPrice;  // Price at the start of the wave (e.g., scaled by 1e8)
        int256 endPrice;    // Price at the end of the wave (if concluded)
        bool isImpulse;     // True if impulse wave (trending); false if corrective wave
        bool active;        // True if the wave is active (recorded); false if removed
    }
    
    // Array storing all waves. Each new wave is appended.
    Wave[] public waves;
    
    // --- Events ---
    event WaveAdded(uint256 indexed waveNumber, uint256 startTime, int256 startPrice, bool isImpulse);
    event WaveUpdated(uint256 indexed waveNumber, uint256 endTime, int256 endPrice);
    event WaveRemoved(uint256 indexed waveNumber);

    /**
     * @notice Adds a new Elliott wave record.
     * @param _startTime The timestamp when the wave starts.
     * @param _startPrice The price at which the wave starts.
     * @param _isImpulse True if the wave is an impulse (trending) wave; false if corrective.
     * @return waveIndex The index (and wave number) of the newly added wave.
     */
    function addWave(
        uint256 _startTime,
        int256 _startPrice,
        bool _isImpulse
    ) external onlyOwner returns (uint256 waveIndex) {
        require(_startTime > 0, "Start time must be > 0");
        // Optionally, enforce _startPrice > 0 if required for your analysis.

        waveIndex = waves.length;
        waves.push(Wave({
            waveNumber: waveIndex,
            startTime: _startTime,
            endTime: 0,
            startPrice: _startPrice,
            endPrice: 0,
            isImpulse: _isImpulse,
            active: true
        }));
        emit WaveAdded(waveIndex, _startTime, _startPrice, _isImpulse);
    }

    /**
     * @notice Updates an existing wave by setting its end time and end price.
     * @param waveIndex The index of the wave to update.
     * @param _endTime The timestamp when the wave ended.
     * @param _endPrice The price at which the wave ended.
     */
    function updateWave(
        uint256 waveIndex,
        uint256 _endTime,
        int256 _endPrice
    ) external onlyOwner {
        require(waveIndex < waves.length, "Wave does not exist");
        Wave storage w = waves[waveIndex];
        require(w.active, "Wave not active");
        require(_endTime >= w.startTime, "End time must be >= start time");

        w.endTime = _endTime;
        w.endPrice = _endPrice;
        emit WaveUpdated(w.waveNumber, _endTime, _endPrice);
    }

    /**
     * @notice Marks a wave as removed (inactive).
     * @param waveIndex The index of the wave to remove.
     */
    function removeWave(uint256 waveIndex) external onlyOwner {
        require(waveIndex < waves.length, "Wave does not exist");
        Wave storage w = waves[waveIndex];
        require(w.active, "Wave already removed");

        w.active = false;
        emit WaveRemoved(w.waveNumber);
    }

    /**
     * @notice Returns the total number of waves recorded (including inactive).
     * @return The number of wave records.
     */
    function totalWaves() external view returns (uint256) {
        return waves.length;
    }
}
