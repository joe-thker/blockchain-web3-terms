// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title LaunchData
/// @notice This contract manages launch events. The owner can add, update, or remove events.
/// Each event stores a unique ID, name, description, launch date, target amount, and active status.
contract LaunchData is Ownable, ReentrancyGuard {
    /// @notice Structure representing a launch event.
    struct LaunchEvent {
        uint256 id;
        string name;
        string description;
        uint256 launchDate; // Timestamp when the event is scheduled
        uint256 target;     // Target amount (could be funds, units, etc.)
        bool active;        // Whether the event is active
    }

    // Incremental counter for launch event IDs.
    uint256 public nextLaunchId;
    // Mapping from launch event ID to event details.
    mapping(uint256 => LaunchEvent) public launches;
    // Array to store active launch event IDs (for enumeration).
    uint256[] public launchIds;

    // --- Events ---
    event LaunchAdded(uint256 indexed launchId, string name, uint256 launchDate, uint256 target);
    event LaunchUpdated(uint256 indexed launchId, string name, uint256 launchDate, uint256 target, bool active);
    event LaunchRemoved(uint256 indexed launchId);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // No additional initialization required.
    }

    /// @notice Adds a new launch event.
    /// @param name The name of the launch.
    /// @param description A description of the launch.
    /// @param launchDate The scheduled launch date (must be in the future).
    /// @param target The target amount (units, funds, etc.) for the launch.
    /// @return launchId The unique ID of the new launch event.
    function addLaunch(
        string calldata name,
        string calldata description,
        uint256 launchDate,
        uint256 target
    ) external onlyOwner nonReentrant returns (uint256 launchId) {
        require(launchDate > block.timestamp, "Launch date must be in the future");
        launchId = nextLaunchId;
        nextLaunchId++;

        launches[launchId] = LaunchEvent({
            id: launchId,
            name: name,
            description: description,
            launchDate: launchDate,
            target: target,
            active: true
        });
        launchIds.push(launchId);

        emit LaunchAdded(launchId, name, launchDate, target);
    }

    /// @notice Updates an existing launch event.
    /// @param launchId The ID of the launch event to update.
    /// @param name The new name.
    /// @param description The new description.
    /// @param launchDate The new launch date (must be in the future).
    /// @param target The new target amount.
    /// @param active The new active status.
    function updateLaunch(
        uint256 launchId,
        string calldata name,
        string calldata description,
        uint256 launchDate,
        uint256 target,
        bool active
    ) external onlyOwner nonReentrant {
        require(launchId < nextLaunchId, "Launch event does not exist");
        require(launchDate > block.timestamp, "Launch date must be in the future");

        LaunchEvent storage launch = launches[launchId];
        launch.name = name;
        launch.description = description;
        launch.launchDate = launchDate;
        launch.target = target;
        launch.active = active;

        emit LaunchUpdated(launchId, name, launchDate, target, active);
    }

    /// @notice Removes an existing launch event.
    /// @param launchId The ID of the launch event to remove.
    function removeLaunch(uint256 launchId) external onlyOwner nonReentrant {
        require(launchId < nextLaunchId, "Launch event does not exist");
        delete launches[launchId];

        // Remove launchId from the launchIds array.
        for (uint256 i = 0; i < launchIds.length; i++) {
            if (launchIds[i] == launchId) {
                launchIds[i] = launchIds[launchIds.length - 1];
                launchIds.pop();
                break;
            }
        }

        emit LaunchRemoved(launchId);
    }

    /// @notice Retrieves the details of a launch event.
    /// @param launchId The ID of the launch event.
    /// @return The LaunchEvent struct for the given ID.
    function getLaunch(uint256 launchId) external view returns (LaunchEvent memory) {
        require(launchId < nextLaunchId, "Launch event does not exist");
        return launches[launchId];
    }

    /// @notice Retrieves all active launch event IDs.
    /// @return An array of launch event IDs.
    function getAllLaunchIds() external view returns (uint256[] memory) {
        return launchIds;
    }
}
