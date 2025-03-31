// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DecentralizationRatio
/// @notice Contract to dynamically track and record decentralization ratio metrics.
contract DecentralizationRatio is Ownable, ReentrancyGuard {

    /// @notice Struct to store decentralization ratio records.
    struct RatioRecord {
        uint256 ratio; // Scaled by 10,000 (e.g., 50% = 5000)
        string details;
        uint256 timestamp;
    }

    // Array to store historical decentralization ratio records.
    RatioRecord[] private ratioRecords;

    // Authorized addresses allowed to update ratio
    mapping(address => bool) public authorizedUpdaters;

    // Events
    event RatioUpdated(uint256 indexed index, uint256 ratio, string details, uint256 timestamp);
    event UpdaterAuthorized(address indexed updater);
    event UpdaterRevoked(address indexed updater);

    /// @notice Modifier to check if the sender is authorized to update.
    modifier onlyAuthorized() {
        require(authorizedUpdaters[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    /// @notice Constructor sets deployer as initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Owner authorizes an address to update ratios.
    function authorizeUpdater(address updater) external onlyOwner {
        require(updater != address(0), "Invalid address");
        authorizedUpdaters[updater] = true;
        emit UpdaterAuthorized(updater);
    }

    /// @notice Owner revokes an updater’s authorization.
    function revokeUpdater(address updater) external onlyOwner {
        require(authorizedUpdaters[updater], "Updater not authorized");
        authorizedUpdaters[updater] = false;
        emit UpdaterRevoked(updater);
    }

    /// @notice Authorized address updates the decentralization ratio.
    /// @param ratio Decentralization ratio scaled by 10,000 (e.g., 50% = 5000)
    /// @param details Description or details about the measurement.
    function updateRatio(uint256 ratio, string calldata details) external onlyAuthorized nonReentrant {
        require(ratio <= 10000, "Ratio cannot exceed 100% (10000)");

        RatioRecord memory newRecord = RatioRecord({
            ratio: ratio,
            details: details,
            timestamp: block.timestamp
        });

        ratioRecords.push(newRecord);

        emit RatioUpdated(ratioRecords.length - 1, ratio, details, block.timestamp);
    }

    /// @notice Retrieve the latest decentralization ratio.
    function getLatestRatio() external view returns (RatioRecord memory) {
        require(ratioRecords.length > 0, "No records available");
        return ratioRecords[ratioRecords.length - 1];
    }

    /// @notice Retrieve a specific historical record by index.
    function getRatioRecord(uint256 index) external view returns (RatioRecord memory) {
        require(index < ratioRecords.length, "Index out of bounds");
        return ratioRecords[index];
    }

    /// @notice Returns the total number of recorded ratios.
    function totalRatios() external view returns (uint256) {
        return ratioRecords.length;
    }
}
