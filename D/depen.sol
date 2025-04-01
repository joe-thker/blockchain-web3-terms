// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DePenRegistry
/// @notice A dynamic, optimized, and secure registry for “DePen” (e.g. “Decentralized Physical Infrastructure”)
/// nodes or resources. The owner can register, update, and remove nodes, while an array tracks active node IDs
/// for enumeration.
contract DePenRegistry is Ownable, ReentrancyGuard {
    /// @notice Structure representing a “DePen” node or resource.
    struct DePenNode {
        uint256 id;
        address owner;
        string infoURI;  // URI to off-chain info or metadata about this node
        bool active;
        uint256 registeredAt;
    }

    // Auto-incremented ID counter for DePen nodes.
    uint256 public nextNodeId;

    // Mapping from node ID to DePenNode details.
    mapping(uint256 => DePenNode) public nodes;
    // Array of currently active node IDs for enumeration.
    uint256[] private activeNodeIds;

    // --- Events ---
    event NodeRegistered(uint256 indexed nodeId, address indexed owner, string infoURI, uint256 timestamp);
    event NodeUpdated(uint256 indexed nodeId, string newInfoURI, uint256 timestamp);
    event NodeRemoved(uint256 indexed nodeId, uint256 timestamp);

    /// @notice Constructor sets deployer as initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Registers a new DePen node dynamically.
    /// @param infoURI A URI pointing to metadata about the node (e.g., IPFS, web link).
    /// @return nodeId The unique ID of the newly registered node.
    function registerNode(string calldata infoURI) external nonReentrant returns (uint256 nodeId) {
        require(bytes(infoURI).length > 0, "Info URI is required");

        nodeId = nextNodeId++;
        nodes[nodeId] = DePenNode({
            id: nodeId,
            owner: msg.sender,
            infoURI: infoURI,
            active: true,
            registeredAt: block.timestamp
        });
        activeNodeIds.push(nodeId);

        emit NodeRegistered(nodeId, msg.sender, infoURI, block.timestamp);
    }

    /// @notice Updates info about a DePen node. Only the node owner can call this.
    /// @param nodeId The ID of the node to update.
    /// @param newInfoURI The updated URI pointing to node metadata.
    function updateNode(uint256 nodeId, string calldata newInfoURI) external nonReentrant {
        DePenNode storage node = nodes[nodeId];
        require(node.active, "Node not active");
        require(node.owner == msg.sender, "Not node owner");
        require(bytes(newInfoURI).length > 0, "Info URI required");

        node.infoURI = newInfoURI;
        // Optionally update the timestamp to reflect last update time
        node.registeredAt = block.timestamp;

        emit NodeUpdated(nodeId, newInfoURI, block.timestamp);
    }

    /// @notice Removes (marks as inactive) a node from the registry. Only the node owner or contract owner can do this.
    /// @param nodeId The ID of the node to remove.
    function removeNode(uint256 nodeId) external nonReentrant {
        DePenNode storage node = nodes[nodeId];
        require(node.active, "Node already inactive");
        require(node.owner == msg.sender || msg.sender == owner(), "Unauthorized");

        node.active = false;
        _removeNodeId(nodeId);

        emit NodeRemoved(nodeId, block.timestamp);
    }

    /// @notice Internal function to remove a node ID from the active list array.
    /// @param nodeId The ID of the node to remove from active listing.
    function _removeNodeId(uint256 nodeId) internal {
        uint256 length = activeNodeIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (activeNodeIds[i] == nodeId) {
                activeNodeIds[i] = activeNodeIds[length - 1];
                activeNodeIds.pop();
                break;
            }
        }
    }

    /// @notice Returns details of a node.
    /// @param nodeId The node’s ID.
    /// @return The DePenNode struct for that ID.
    function getNode(uint256 nodeId) external view returns (DePenNode memory) {
        return nodes[nodeId];
    }

    /// @notice Retrieves IDs of all currently active nodes.
    /// @return An array of node IDs.
    function getActiveNodes() external view returns (uint256[] memory) {
        return activeNodeIds;
    }

    /// @notice Returns the total number of nodes ever registered (including inactive).
    /// @return The count of node IDs assigned so far.
    function totalNodes() external view returns (uint256) {
        return nextNodeId;
    }
}
