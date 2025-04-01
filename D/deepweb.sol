// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DeepWebRegistry
/// @notice A decentralized registry for deep web resources (e.g. .onion addresses).
/// The owner can dynamically add, update, and remove resources. Active resource IDs are maintained
/// in an array for efficient enumeration.
contract DeepWebRegistry is Ownable, ReentrancyGuard {
    /// @notice Structure to store deep web resource details.
    struct Resource {
        uint256 id;
        string onionAddress; // e.g. .onion address
        string description;  // Additional details or metadata
        uint256 timestamp;   // When the resource was added/updated
        bool active;         // Whether the resource is active
    }

    // Incremental counter for resource IDs.
    uint256 public nextResourceId;
    // Mapping from resource ID to Resource.
    mapping(uint256 => Resource) private resources;
    // Array of active resource IDs for enumeration.
    uint256[] private activeResourceIds;

    // --- Events ---
    event ResourceAdded(uint256 indexed id, string onionAddress, string description, uint256 timestamp);
    event ResourceUpdated(uint256 indexed id, string newOnionAddress, string newDescription, uint256 timestamp);
    event ResourceRemoved(uint256 indexed id);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Adds a new deep web resource.
    /// @param onionAddress The .onion address.
    /// @param description A description of the resource.
    /// @return resourceId The unique ID of the newly added resource.
    function addResource(string calldata onionAddress, string calldata description)
        external
        onlyOwner
        nonReentrant
        returns (uint256 resourceId)
    {
        require(bytes(onionAddress).length > 0, "Onion address required");

        resourceId = nextResourceId++;
        resources[resourceId] = Resource({
            id: resourceId,
            onionAddress: onionAddress,
            description: description,
            timestamp: block.timestamp,
            active: true
        });
        activeResourceIds.push(resourceId);

        emit ResourceAdded(resourceId, onionAddress, description, block.timestamp);
    }

    /// @notice Updates an existing deep web resource.
    /// @param resourceId The ID of the resource to update.
    /// @param newOnionAddress The new .onion address.
    /// @param newDescription The new description.
    function updateResource(
        uint256 resourceId,
        string calldata newOnionAddress,
        string calldata newDescription
    ) external onlyOwner nonReentrant {
        require(resources[resourceId].active, "Resource not active");
        require(bytes(newOnionAddress).length > 0, "Onion address required");

        Resource storage resource = resources[resourceId];
        resource.onionAddress = newOnionAddress;
        resource.description = newDescription;
        resource.timestamp = block.timestamp;

        emit ResourceUpdated(resourceId, newOnionAddress, newDescription, block.timestamp);
    }

    /// @notice Removes an existing deep web resource.
    /// @param resourceId The ID of the resource to remove.
    function removeResource(uint256 resourceId) external onlyOwner nonReentrant {
        require(resources[resourceId].active, "Resource not active");

        resources[resourceId].active = false;
        _removeActiveResource(resourceId);

        emit ResourceRemoved(resourceId);
    }

    /// @notice Internal function to remove a resource ID from the active array.
    /// @param resourceId The resource ID to remove.
    function _removeActiveResource(uint256 resourceId) internal {
        uint256 length = activeResourceIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (activeResourceIds[i] == resourceId) {
                activeResourceIds[i] = activeResourceIds[length - 1];
                activeResourceIds.pop();
                break;
            }
        }
    }

    /// @notice Retrieves details of a resource by ID.
    /// @param resourceId The resource ID.
    /// @return The Resource struct.
    function getResource(uint256 resourceId) external view returns (Resource memory) {
        require(resources[resourceId].active, "Resource not active or does not exist");
        return resources[resourceId];
    }

    /// @notice Retrieves all active resource IDs.
    /// @return An array of active resource IDs.
    function getActiveResourceIds() external view returns (uint256[] memory) {
        return activeResourceIds;
    }

    /// @notice Retrieves the total number of resources created (including inactive).
    /// @return The total resource count.
    function totalResources() external view returns (uint256) {
        return nextResourceId;
    }
}
