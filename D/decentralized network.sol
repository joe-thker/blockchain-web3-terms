// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DecentralizedNetwork
/// @notice Dynamic registry for decentralized network nodes.
contract DecentralizedNetwork is Ownable, ReentrancyGuard {

    struct Node {
        uint256 nodeId;
        address owner;
        string nodeURI;    // Endpoint or identifier for the node
        uint256 reputation;
        bool active;
        uint256 lastUpdated;
    }

    uint256 private nextNodeId;
    mapping(uint256 => Node) public nodes;
    mapping(address => uint256[]) private ownerNodes;

    event NodeRegistered(uint256 indexed nodeId, address indexed owner, string nodeURI);
    event NodeUpdated(uint256 indexed nodeId, string newURI);
    event NodeRemoved(uint256 indexed nodeId);
    event ReputationUpdated(uint256 indexed nodeId, uint256 newReputation);

    constructor() Ownable(msg.sender) {}

    /// @notice Register a node dynamically
    function registerNode(string calldata nodeURI) external nonReentrant {
        require(bytes(nodeURI).length > 0, "Node URI required");

        uint256 nodeId = nextNodeId++;
        nodes[nodeId] = Node({
            nodeId: nodeId,
            owner: msg.sender,
            nodeURI: nodeURI,
            reputation: 100, // Default reputation
            active: true,
            lastUpdated: block.timestamp
        });

        ownerNodes[msg.sender].push(nodeId);

        emit NodeRegistered(nodeId, msg.sender, nodeURI);
    }

    /// @notice Update node URI dynamically
    function updateNodeURI(uint256 nodeId, string calldata newURI) external nonReentrant {
        Node storage node = nodes[nodeId];
        require(node.owner == msg.sender, "Not node owner");
        require(node.active, "Node inactive");
        require(bytes(newURI).length > 0, "URI required");

        node.nodeURI = newURI;
        node.lastUpdated = block.timestamp;

        emit NodeUpdated(nodeId, newURI);
    }

    /// @notice Owner updates node reputation dynamically
    function updateReputation(uint256 nodeId, uint256 newReputation) external onlyOwner nonReentrant {
        require(nodes[nodeId].active, "Node inactive");
        nodes[nodeId].reputation = newReputation;
        nodes[nodeId].lastUpdated = block.timestamp;

        emit ReputationUpdated(nodeId, newReputation);
    }

    /// @notice Remove node dynamically
    function removeNode(uint256 nodeId) external nonReentrant {
        Node storage node = nodes[nodeId];
        require(node.owner == msg.sender || msg.sender == owner(), "Unauthorized");
        require(node.active, "Already inactive");

        node.active = false;

        emit NodeRemoved(nodeId);
    }

    /// @notice Get node details by nodeId
    function getNode(uint256 nodeId) external view returns (Node memory) {
        return nodes[nodeId];
    }

    /// @notice Get all node IDs owned by an address
    function getNodesByOwner(address nodeOwner) external view returns (uint256[] memory) {
        return ownerNodes[nodeOwner];
    }

    /// @notice Get total number of nodes registered
    function totalNodes() external view returns (uint256) {
        return nextNodeId;
    }
}
