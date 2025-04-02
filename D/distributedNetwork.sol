// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DistributedNetwork
/// @notice A dynamic and optimized contract for managing a set of nodes and edges in a distributed network.
/// Unlike a DAG approach, we allow cycles. The owner can add or remove nodes, and add or remove edges.
contract DistributedNetwork is Ownable, ReentrancyGuard {
    /// @notice Structure for storing node info, including a metadata string.
    struct Node {
        uint256 id;
        bool active;
        string metadata;
    }

    // Incremental ID for nodes.
    uint256 public nextNodeId;

    // Array storing all nodes, including removed ones. Index = nodeId.
    Node[] public nodes;

    // Adjacency list: mapping nodeId => array of connected node IDs (outgoing edges).
    mapping(uint256 => uint256[]) public adjacency;

    // --- Events ---
    event NodeCreated(uint256 indexed nodeId, string metadata);
    event NodeUpdated(uint256 indexed nodeId, string newMetadata);
    event NodeRemoved(uint256 indexed nodeId);

    event EdgeAdded(uint256 indexed from, uint256 indexed to);
    event EdgeRemoved(uint256 indexed from, uint256 indexed to);

    /// @notice Constructor sets the deployer as initial owner. 
    /// Call Ownable(msg.sender) to fix “no arguments to base constructor” error.
    constructor() Ownable(msg.sender) {}

    /// @notice Creates a new node with optional metadata. Only owner can create nodes.
    /// @param metadata A string describing or labeling this node.
    /// @return nodeId The ID assigned to the newly created node.
    function createNode(string calldata metadata)
        external
        onlyOwner
        nonReentrant
        returns (uint256 nodeId)
    {
        nodeId = nextNodeId++;
        nodes.push(Node({
            id: nodeId,
            active: true,
            metadata: metadata
        }));
        emit NodeCreated(nodeId, metadata);
    }

    /// @notice Updates the metadata for an existing node. Only owner can update.
    /// @param nodeId The ID of the node to update.
    /// @param newMetadata The new string metadata for this node.
    function updateNode(uint256 nodeId, string calldata newMetadata)
        external
        onlyOwner
        nonReentrant
    {
        require(nodeId < nodes.length, "Node ID out of range");
        Node storage nd = nodes[nodeId];
        require(nd.active, "Node is inactive");

        nd.metadata = newMetadata;
        emit NodeUpdated(nodeId, newMetadata);
    }

    /// @notice Removes (marks inactive) an existing node, preventing future edges from or to it. Only owner can remove.
    /// @param nodeId The ID of the node to remove.
    function removeNode(uint256 nodeId) external onlyOwner nonReentrant {
        require(nodeId < nodes.length, "Node ID out of range");
        Node storage nd = nodes[nodeId];
        require(nd.active, "Node already inactive");

        nd.active = false;
        emit NodeRemoved(nodeId);
    }

    /// @notice Adds a directed edge from node `from` to node `to`. This can create cycles.
    /// @param from The ID of the source node.
    /// @param to The ID of the target node.
    function addEdge(uint256 from, uint256 to) external onlyOwner nonReentrant {
        require(from < nodes.length && to < nodes.length, "Node ID out of range");
        require(nodes[from].active && nodes[to].active, "One or both nodes are inactive");
        // You can allow self-loops or revert. For demonstration, let's revert if from==to.
        require(from != to, "No self-loop allowed");

        // optional check to avoid duplicate edges:
        uint256[] storage children = adjacency[from];
        for (uint256 i = 0; i < children.length; i++) {
            require(children[i] != to, "Edge already exists");
        }

        adjacency[from].push(to);
        emit EdgeAdded(from, to);
    }

    /// @notice Removes a directed edge from node `from` to node `to`. Only owner can remove edges.
    /// @param from The ID of the source node.
    /// @param to The ID of the target node.
    function removeEdge(uint256 from, uint256 to) external onlyOwner nonReentrant {
        require(from < nodes.length && to < nodes.length, "Node ID out of range");

        uint256[] storage children = adjacency[from];
        for (uint256 i = 0; i < children.length; i++) {
            if (children[i] == to) {
                // remove by swapping with last and popping
                children[i] = children[children.length - 1];
                children.pop();
                emit EdgeRemoved(from, to);
                return;
            }
        }
        revert("Edge not found");
    }

    /// @notice Returns the Node struct for a given nodeId.
    /// @param nodeId The ID of the node to query.
    /// @return A Node struct with id, active, and metadata fields.
    function getNode(uint256 nodeId) external view returns (Node memory) {
        require(nodeId < nodes.length, "Node ID out of range");
        return nodes[nodeId];
    }

    /// @notice Returns the array of node IDs that the given node points to (outgoing edges).
    /// @param nodeId The ID of the node.
    /// @return An array of node IDs.
    function getChildren(uint256 nodeId) external view returns (uint256[] memory) {
        require(nodeId < nodes.length, "Node ID out of range");
        return adjacency[nodeId];
    }

    /// @notice Returns the total number of nodes ever created (including inactive).
    /// @return The length of the `nodes` array.
    function totalNodes() external view returns (uint256) {
        return nodes.length;
    }
}
