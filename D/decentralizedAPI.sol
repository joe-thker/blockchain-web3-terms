// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DecentralizedAPI
/// @notice Manages decentralized API endpoints dynamically and securely.
contract DecentralizedAPI is Ownable, ReentrancyGuard {

    /// @notice Struct to store API endpoint details
    struct APIEndpoint {
        uint256 id;
        string name;
        string url;
        string description;
        bool active;
        uint256 timestamp;
    }

    // Incremental counter for endpoints
    uint256 private nextApiId;

    // Mapping API ID to APIEndpoint struct
    mapping(uint256 => APIEndpoint) private endpoints;

    // Array of active API IDs for enumeration
    uint256[] private activeApiIds;

    // Events
    event ApiEndpointAdded(uint256 indexed id, string name, string url);
    event ApiEndpointUpdated(uint256 indexed id, string name, string url, bool active);
    event ApiEndpointRemoved(uint256 indexed id);

    constructor() Ownable(msg.sender) {}

    /// @notice Add a new API endpoint dynamically
    function addApiEndpoint(
        string calldata name,
        string calldata url,
        string calldata description
    ) external onlyOwner nonReentrant returns (uint256) {
        require(bytes(name).length > 0, "Name required");
        require(bytes(url).length > 0, "URL required");

        uint256 currentId = nextApiId++;
        endpoints[currentId] = APIEndpoint({
            id: currentId,
            name: name,
            url: url,
            description: description,
            active: true,
            timestamp: block.timestamp
        });

        activeApiIds.push(currentId);
        emit ApiEndpointAdded(currentId, name, url);

        return currentId;
    }

    /// @notice Update existing API endpoint details dynamically
    function updateApiEndpoint(
        uint256 id,
        string calldata name,
        string calldata url,
        string calldata description,
        bool active
    ) external onlyOwner nonReentrant {
        require(bytes(name).length > 0, "Name required");
        require(bytes(url).length > 0, "URL required");
        require(endpoints[id].timestamp != 0, "Endpoint does not exist");

        endpoints[id].name = name;
        endpoints[id].url = url;
        endpoints[id].description = description;
        endpoints[id].active = active;

        // Update activeApiIds array
        if (!active) {
            _removeFromActiveList(id);
        } else if (!_isActive(id)) {
            activeApiIds.push(id);
        }

        emit ApiEndpointUpdated(id, name, url, active);
    }

    /// @notice Remove an API endpoint completely
    function removeApiEndpoint(uint256 id) external onlyOwner nonReentrant {
        require(endpoints[id].timestamp != 0, "Endpoint does not exist");

        delete endpoints[id];
        _removeFromActiveList(id);

        emit ApiEndpointRemoved(id);
    }

    /// @notice Internal helper to remove an ID from active list efficiently
    function _removeFromActiveList(uint256 id) internal {
        uint256 length = activeApiIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (activeApiIds[i] == id) {
                activeApiIds[i] = activeApiIds[length - 1];
                activeApiIds.pop();
                break;
            }
        }
    }

    /// @notice Checks if an API endpoint is already active
    function _isActive(uint256 id) internal view returns (bool) {
        uint256 length = activeApiIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (activeApiIds[i] == id) {
                return true;
            }
        }
        return false;
    }

    /// @notice Retrieve details of an API endpoint by ID
    function getApiEndpoint(uint256 id) external view returns (APIEndpoint memory) {
        require(endpoints[id].timestamp != 0, "Endpoint does not exist");
        return endpoints[id];
    }

    /// @notice Retrieve all active API IDs
    function getActiveApiIds() external view returns (uint256[] memory) {
        return activeApiIds;
    }

    /// @notice Get total count of registered API endpoints
    function totalApiEndpoints() external view returns (uint256) {
        return nextApiId;
    }
}
