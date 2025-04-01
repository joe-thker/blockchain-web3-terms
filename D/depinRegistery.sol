// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DePinRegistry
/// @notice A dynamic, optimized, and secure registry for Decentralized Physical Infrastructure (DePin) nodes.
/// The owner and node owners can register, update, and remove DePin nodes, with an array tracking active nodes.
contract DePinRegistry is Ownable, ReentrancyGuard {
    /// @notice Structure representing a DePin node.
    struct DePinNode {
        uint256 id;
        address owner;
        string metadataURI;  // e.g. IPFS or any off-chain URI with node details
        bool active;
        uint256 registeredAt;
    }

    // Auto-incremented node ID counter
    uint256 public nextNodeId;

    // Mapping from node ID to DePinNode details
    mapping(uint256 => DePinNode) public nodes;
    // Array storing the IDs of currently active nodes
    uint256[] private activeNodeIds;

    // --- Events ---
    event NodeRegistered(uint256 indexed id, address indexed owner, string metadataURI, uint256 timestamp);
    event NodeUpdated(uint256 indexed id, string newMetadataURI, uint256 timestamp);
    event NodeRemoved(uint256 indexed id, uint256 timestamp);

    /// @notice Constructor sets the deployer as initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Registers a new DePin node dynamically.
    /// @param metadataURI A URI containing node metadata (e.g., IPFS link).
    /// @return nodeId The unique ID of the newly registered node.
    function registerNode(string calldata metadataURI)
        external
        nonReentrant
        returns (uint256 nodeId)
    {
        require(bytes(metadataURI).length > 0, "Metadata URI is required");

        nodeId = nextNodeId++;
        nodes[nodeId] = DePinNode({
            id: nodeId,
            owner: msg.sender,
            metadataURI: metadataURI,
            active: true,
            registeredAt: block.timestamp
        });
        activeNodeIds.push(nodeId);

        emit NodeRegistered(nodeId, msg.sender, metadataURI, block.timestamp);
    }

    /// @notice Updates the metadata of an existing DePin node. Only the node owner can call this.
    /// @param nodeId The ID of the node to update.
    /// @param newMetadataURI The updated URI containing node metadata.
    function updateNode(uint256 nodeId, string calldata newMetadataURI) external nonReentrant {
        DePinNode storage node = nodes[nodeId];
        require(node.active, "Node not active");
        require(node.owner == msg.sender, "Not node owner");
        require(bytes(newMetadataURI).length > 0, "Metadata URI required");

        node.metadataURI = newMetadataURI;
        node.registeredAt = block.timestamp;

        emit NodeUpdated(nodeId, newMetadataURI, block.timestamp);
    }

    /// @notice Removes (marks as inactive) a node from the registry. 
    /// Only the node owner or the contract owner can do this.
    /// @param nodeId The ID of the node to remove.
    function removeNode(uint256 nodeId) external nonReentrant {
        DePinNode storage node = nodes[nodeId];
        require(node.active, "Node already inactive");
        require(node.owner == msg.sender || msg.sender == owner(), "Unauthorized");

        node.active = false;
        _removeActiveNodeId(nodeId);

        emit NodeRemoved(nodeId, block.timestamp);
    }

    /// @notice Retrieves details of a node by ID.
    /// @param nodeId The ID of the node.
    /// @return The DePinNode struct for that ID.
    function getNode(uint256 nodeId) external view returns (DePinNode memory) {
        return nodes[nodeId];
    }

    /// @notice Retrieves IDs of all currently active nodes.
    /// @return An array of active node IDs.
    function getActiveNodeIds() external view returns (uint256[] memory) {
        return activeNodeIds;
    }

    /// @notice Returns the total number of nodes ever created (including inactive).
    function totalNodes() external view returns (uint256) {
        return nextNodeId;
    }

    /// @notice Internal function to remove a node ID from the activeNodeIds array.
    /// @param nodeId The ID of the node to remove.
    function _removeActiveNodeId(uint256 nodeId) internal {
        uint256 length = activeNodeIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (activeNodeIds[i] == nodeId) {
                activeNodeIds[i] = activeNodeIds[length - 1];
                activeNodeIds.pop();
                break;
            }
        }
    }
}
