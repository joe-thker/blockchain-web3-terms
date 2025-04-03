// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ErasureCodingDemo
/// @notice This contract demonstrates a simplified erasure coding mechanism by storing data shards on-chain.
/// The owner can add shards and update the threshold (the minimum number of shards required for reconstruction).
/// Anyone can attempt to reconstruct the original data by concatenating all stored shards if the threshold is met.
/// Note: This is a simplified demonstration and does not implement true erasure coding error correction.
contract ErasureCodingDemo is Ownable {
    // Array to store data shards.
    bytes[] public shards;

    // The minimum number of shards required for successful reconstruction.
    uint256 public threshold;

    // --- Events ---
    event ShardAdded(uint256 indexed index, bytes shardData);
    event ThresholdUpdated(uint256 newThreshold);

    /**
     * @notice Constructor sets the initial reconstruction threshold.
     * @param _threshold The minimum number of shards required for reconstruction.
     */
    constructor(uint256 _threshold) Ownable(msg.sender) {
        require(_threshold > 0, "Threshold must be > 0");
        threshold = _threshold;
    }

    /**
     * @notice Adds a new data shard.
     * @param shardData The data for the shard.
     */
    function addShard(bytes calldata shardData) external onlyOwner {
        shards.push(shardData);
        emit ShardAdded(shards.length - 1, shardData);
    }

    /**
     * @notice Updates the reconstruction threshold.
     * @param newThreshold The new threshold value.
     */
    function updateThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Threshold must be > 0");
        threshold = newThreshold;
        emit ThresholdUpdated(newThreshold);
    }

    /**
     * @notice Returns the total number of shards stored.
     * @return The total number of shards.
     */
    function totalShards() external view returns (uint256) {
        return shards.length;
    }

    /**
     * @notice Retrieves a specific shard by index.
     * @param index The index of the shard.
     * @return The shard data.
     */
    function getShard(uint256 index) external view returns (bytes memory) {
        require(index < shards.length, "Index out of range");
        return shards[index];
    }

    /**
     * @notice Reconstructs the original data by concatenating all stored shards.
     * Note: This is a simplified demonstration. Real erasure coding reconstruction involves complex error correction.
     * @return reconstructedData The concatenated data from all shards.
     */
    function reconstructData() external view returns (bytes memory reconstructedData) {
        require(shards.length >= threshold, "Not enough shards for reconstruction");

        uint256 totalLength = 0;
        for (uint256 i = 0; i < shards.length; i++) {
            totalLength += shards[i].length;
        }

        reconstructedData = new bytes(totalLength);
        uint256 offset = 0;
        for (uint256 i = 0; i < shards.length; i++) {
            bytes memory shard = shards[i];
            for (uint256 j = 0; j < shard.length; j++) {
                reconstructedData[offset++] = shard[j];
            }
        }
    }
}
