// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DirectedAcyclicGraph
/// @notice A dynamic, optimized contract for managing a directed acyclic graph (DAG).
/// The owner can add nodes, add edges, and remove nodes. The contract checks for cycles 
/// before adding an edge, reverting if the new edge would create a cycle.
contract DirectedAcyclicGraph is Ownable, ReentrancyGuard {
    /// @notice Structure storing node metadata. Additional fields can be added as needed.
    struct Node {
        uint256 id;
        bool active;
        string metadata;   // optional metadata or label for the node
    }

    // Auto-incremented node ID counter
    uint256 public nextNodeId;

    // Array storing all nodes (including deactivated ones). Index = nodeId.
    Node[] public nodes;

    // Adjacency list: mapping nodeId => array of children (outgoing edges).
    mapping(uint256 => uint256[]) public adjacency;

    // --- Events ---
    event NodeCreated(uint256 indexed nodeId, string metadata);
    event NodeRemoved(uint256 indexed nodeId);
    event EdgeAdded(uint256 indexed from, uint256 indexed to);
    event EdgeRemoved(uint256 indexed from, uint256 indexed to);

    /// @notice Constructor sets deployer as initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Creates a new active node with optional metadata. Only the owner can create nodes.
    /// @param metadata A string storing any label or data for the node.
    /// @return nodeId The ID of the newly created node.
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

    /// @notice Removes (deactivates) a node, preventing further edges from/to this node.
    /// @param nodeId The ID of the node to remove.
    function removeNode(uint256 nodeId) external onlyOwner nonReentrant {
        require(nodeId < nodes.length, "Node ID out of range");
        Node storage nd = nodes[nodeId];
        require(nd.active, "Node already inactive");
        nd.active = false;

        emit NodeRemoved(nodeId);
    }

    /// @notice Adds a directed edge from node `from` to node `to`. Checks if this edge would create a cycle.
    /// @param from The ID of the source node.
    /// @param to The ID of the target node.
    function addEdge(uint256 from, uint256 to) external onlyOwner nonReentrant {
        require(from < nodes.length && to < nodes.length, "Node ID out of range");
        require(nodes[from].active && nodes[to].active, "One or both nodes inactive");
        require(from != to, "No self-loop allowed");

        // Check for existing edge duplication or risk
        // Not strictly required, but we can skip duplicates or revert.
        // For demonstration, let's ensure no duplicate edge.
        uint256[] storage children = adjacency[from];
        for (uint256 i = 0; i < children.length; i++) {
            require(children[i] != to, "Edge already exists");
        }

        // Check if adding this edge would create a cycle:
        // If there's already a path from `to` to `from`, then adding (from->to) creates a cycle.
        require(!_createsCycle(from, to), "Edge creates a cycle");

        // Add the edge
        adjacency[from].push(to);
        emit EdgeAdded(from, to);
    }

    /// @notice Removes a directed edge from node `from` to node `to`.
    /// @param from The ID of the source node.
    /// @param to The ID of the target node.
    function removeEdge(uint256 from, uint256 to) external onlyOwner nonReentrant {
        require(from < nodes.length && to < nodes.length, "Node ID out of range");

        uint256[] storage children = adjacency[from];
        for (uint256 i = 0; i < children.length; i++) {
            if (children[i] == to) {
                // remove the edge by swapping with the last and pop
                children[i] = children[children.length - 1];
                children.pop();
                emit EdgeRemoved(from, to);
                return;
            }
        }
        revert("Edge not found");
    }

    /// @notice Returns the node struct for a given nodeId. Reverts if out of range.
    /// @param nodeId The ID of the node.
    /// @return A Node struct (id, active, metadata).
    function getNode(uint256 nodeId) external view returns (Node memory) {
        require(nodeId < nodes.length, "Node ID out of range");
        return nodes[nodeId];
    }

    /// @notice Returns the list of children (outgoing edges) for a given node.
    /// @param nodeId The ID of the node.
    /// @return An array of node IDs that nodeId points to.
    function getChildren(uint256 nodeId) external view returns (uint256[] memory) {
        require(nodeId < nodes.length, "Node ID out of range");
        return adjacency[nodeId];
    }

    /// @notice Returns the total number of nodes created (including inactive).
    /// @return The length of the nodes array.
    function totalNodes() external view returns (uint256) {
        return nodes.length;
    }

    // --- Internal Functions ---

    /// @notice Checks if adding an edge (from -> to) would create a cycle by seeing if `to` already has a path to `from`.
    /// @dev Uses a DFS approach to see if `from` is reachable from `to`.
    /// @param from The source node where the edge would originate.
    /// @param to The target node for the new edge.
    /// @return True if the new edge would create a cycle, false otherwise.
    function _createsCycle(uint256 from, uint256 to) internal view returns (bool) {
        // If we can reach `from` starting from `to`, then an edge (from->to) forms a cycle.

        // Simple stack-based DFS
        // visited array to avoid repeating
        bool[] memory visited = new bool[](nodes.length);
        uint256[] memory stack = new uint256[](nodes.length);
        uint256 stackSize = 0;

        // push `to`
        stack[stackSize++] = to;

        while (stackSize > 0) {
            uint256 current = stack[--stackSize];
            if (current == from) {
                return true; // found a path from `to` to `from`
            }
            if (!visited[current]) {
                visited[current] = true;
                // push children of `current`
                uint256[] storage children = adjacency[current];
                for (uint256 i = 0; i < children.length; i++) {
                    // only push active children for cycle check
                    if (nodes[children[i]].active && !visited[children[i]]) {
                        stack[stackSize++] = children[i];
                    }
                }
            }
        }
        // no path found
        return false;
    }
}
