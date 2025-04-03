// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title EdgeNodeManager
/// @notice A dynamic and optimized contract to manage "edge nodes." The owner can create nodes,
/// remove them, and reassign node ownership if needed. Node owners can update their node metadata.
contract EdgeNodeManager is Ownable, ReentrancyGuard {
    /// @notice Structure representing an edge node.
    struct EdgeNode {
        uint256 id;
        address nodeOwner;
        string metadata;   // Description, IPFS hash, or other metadata
        bool active;
        uint256 registeredAt;
    }

    // Auto-incremented ID for edge nodes
    uint256 public nextNodeId;

    // Array storing EdgeNode records (including removed ones). The index is nodeId.
    EdgeNode[] public nodes;

    // Mapping from nodeOwner => array of node IDs owned by that address (for easy lookup if needed)
    mapping(address => uint256[]) public ownerNodeIds;

    // --- Events ---
    event NodeCreated(uint256 indexed nodeId, address indexed nodeOwner, string metadata);
    event NodeOwnerTransferred(uint256 indexed nodeId, address indexed oldOwner, address indexed newOwner);
    event NodeUpdated(uint256 indexed nodeId, string newMetadata);
    event NodeRemoved(uint256 indexed nodeId);

    /// @notice Constructor sets deployer as initial owner. 
    /// In this minimal approach, no further initialization is needed.
    constructor() Ownable(msg.sender) {}

    // ------------------------------------------------------------------------
    // Node Registration
    // ------------------------------------------------------------------------

    /// @notice Creates a new edge node with metadata, assigning ownership to `nodeOwner`.
    /// Only the contract owner can create new nodes (or you can let anyone create nodes if you prefer).
    /// @param nodeOwner The address that will own and manage the node.
    /// @param metadata A string containing info about the node (IPFS hash, endpoint info, etc.).
    /// @return nodeId The unique ID assigned to the newly created node.
    function createNode(address nodeOwner, string calldata metadata)
        external
        onlyOwner
        nonReentrant
        returns (uint256 nodeId)
    {
        require(nodeOwner != address(0), "Invalid node owner address");

        nodeId = nextNodeId++;
        nodes.push(EdgeNode({
            id: nodeId,
            nodeOwner: nodeOwner,
            metadata: metadata,
            active: true,
            registeredAt: block.timestamp
        }));

        ownerNodeIds[nodeOwner].push(nodeId);

        emit NodeCreated(nodeId, nodeOwner, metadata);
    }

    /// @notice Transfers ownership of a node to a new owner. 
    /// Only the current nodeOwner or the contract owner can do this. 
    /// @param nodeId The ID of the node to transfer.
    /// @param newOwner The new owner address for the node.
    function transferNodeOwnership(uint256 nodeId, address newOwner) external nonReentrant {
        require(nodeId < nodes.length, "Node ID out of range");
        require(newOwner != address(0), "Invalid address");

        EdgeNode storage nd = nodes[nodeId];
        require(nd.active, "Node not active");
        require(msg.sender == nd.nodeOwner || msg.sender == owner(), "Not authorized to transfer node ownership");

        // Remove nodeId from old ownerNodeIds array
        uint256[] storage oldList = ownerNodeIds[nd.nodeOwner];
        for (uint256 i = 0; i < oldList.length; i++) {
            if (oldList[i] == nodeId) {
                oldList[i] = oldList[oldList.length - 1];
                oldList.pop();
                break;
            }
        }

        // Set new owner
        address oldOwner = nd.nodeOwner;
        nd.nodeOwner = newOwner;
        ownerNodeIds[newOwner].push(nodeId);

        emit NodeOwnerTransferred(nodeId, oldOwner, newOwner);
    }

    /// @notice Updates the metadata of an existing node. Only the node's owner can update it.
    /// @param nodeId The ID of the node to update.
    /// @param newMetadata The new metadata string.
    function updateNode(uint256 nodeId, string calldata newMetadata) external nonReentrant {
        require(nodeId < nodes.length, "Node ID out of range");

        EdgeNode storage nd = nodes[nodeId];
        require(nd.active, "Node not active");
        require(msg.sender == nd.nodeOwner, "Not node owner");

        nd.metadata = newMetadata;
        emit NodeUpdated(nodeId, newMetadata);
    }

    /// @notice Removes (marks as inactive) a node. Only the contract owner can remove nodes in this design.
    /// If you prefer, you can allow the nodeOwner to remove their own node as well.
    /// @param nodeId The ID of the node to remove.
    function removeNode(uint256 nodeId) external onlyOwner nonReentrant {
        require(nodeId < nodes.length, "Node ID out of range");

        EdgeNode storage nd = nodes[nodeId];
        require(nd.active, "Node already inactive");

        nd.active = false;

        // Remove from the nodeOwner’s list
        uint256[] storage list = ownerNodeIds[nd.nodeOwner];
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == nodeId) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }

        emit NodeRemoved(nodeId);
    }

    // ------------------------------------------------------------------------
    // View Functions
    // ------------------------------------------------------------------------

    /// @notice Returns the total number of nodes ever created (including inactive).
    function totalNodes() external view returns (uint256) {
        return nodes.length;
    }

    /// @notice Returns an EdgeNode struct for a given nodeId.
    /// @param nodeId The ID of the node.
    function getNode(uint256 nodeId) external view returns (EdgeNode memory) {
        require(nodeId < nodes.length, "Node ID out of range");
        return nodes[nodeId];
    }

    /// @notice Returns the node IDs owned by a particular address.
    /// @param nodeOwner The owner address.
    /// @return An array of node IDs that belong to `nodeOwner`.
    function getNodeIdsByOwner(address nodeOwner) external view returns (uint256[] memory) {
        return ownerNodeIds[nodeOwner];
    }
}
