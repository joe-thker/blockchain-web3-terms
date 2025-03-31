// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DarkNodes
/// @notice This contract manages the registration and staking of "dark nodes"—nodes that provide specialized services.
/// Nodes register by staking Ether and must maintain a minimum stake to remain active. The owner can update the minimum stake
/// and remove nodes if necessary.
contract DarkNodes is Ownable, ReentrancyGuard {
    /// @notice Structure representing a dark node.
    struct DarkNode {
        address nodeAddress; // Address of the node.
        uint256 stake;       // Amount of Ether staked.
        uint256 registeredAt;// Timestamp when the node registered.
        bool active;         // Whether the node is active.
    }

    // Mapping from node address to its details.
    mapping(address => DarkNode) public darkNodes;
    // List of active node addresses.
    address[] public nodeList;

    // Minimum stake required to register as a dark node (in wei).
    uint256 public minStake;

    // --- Events ---
    event NodeRegistered(address indexed node, uint256 stake, uint256 timestamp);
    event StakeUpdated(address indexed node, uint256 newStake);
    event NodeRemoved(address indexed node, uint256 timestamp);
    event MinStakeUpdated(uint256 newMinStake);

    /// @notice Constructor sets the initial minimum stake.
    /// @param _minStake The minimum amount (in wei) required to register as a dark node.
    constructor(uint256 _minStake) Ownable(msg.sender) {
        require(_minStake > 0, "Minimum stake must be > 0");
        minStake = _minStake;
    }

    /// @notice Allows the owner to update the minimum stake requirement.
    /// @param _minStake The new minimum stake requirement (in wei).
    function updateMinStake(uint256 _minStake) external onlyOwner {
        require(_minStake > 0, "Minimum stake must be > 0");
        minStake = _minStake;
        emit MinStakeUpdated(_minStake);
    }

    /// @notice Registers the caller as a dark node by staking Ether.
    /// The caller must send at least the minimum stake.
    function registerNode() external payable nonReentrant {
        require(msg.value >= minStake, "Insufficient stake to register as dark node");
        require(!darkNodes[msg.sender].active, "Already registered as dark node");

        darkNodes[msg.sender] = DarkNode({
            nodeAddress: msg.sender,
            stake: msg.value,
            registeredAt: block.timestamp,
            active: true
        });
        nodeList.push(msg.sender);
        emit NodeRegistered(msg.sender, msg.value, block.timestamp);
    }

    /// @notice Allows a registered dark node to add more stake.
    function addStake() external payable nonReentrant {
        require(darkNodes[msg.sender].active, "Not a registered dark node");
        require(msg.value > 0, "Must send Ether to add stake");

        darkNodes[msg.sender].stake += msg.value;
        emit StakeUpdated(msg.sender, darkNodes[msg.sender].stake);
    }

    /// @notice Allows a registered dark node to withdraw part of their stake.
    /// If their stake falls below the minimum, the node is automatically removed.
    /// @param amount The amount of Ether (in wei) to withdraw.
    function withdrawStake(uint256 amount) external nonReentrant {
        require(darkNodes[msg.sender].active, "Not a registered dark node");
        require(amount > 0, "Amount must be > 0");
        require(darkNodes[msg.sender].stake >= amount, "Insufficient stake");

        darkNodes[msg.sender].stake -= amount;
        // If the remaining stake is below the minimum, remove the node.
        if (darkNodes[msg.sender].stake < minStake) {
            _removeNode(msg.sender);
        } else {
            emit StakeUpdated(msg.sender, darkNodes[msg.sender].stake);
        }

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Allows the owner to remove a dark node.
    /// @param node The address of the node to remove.
    function removeNode(address node) external onlyOwner nonReentrant {
        require(darkNodes[node].active, "Node is not active");
        _removeNode(node);
    }

    /// @notice Internal function to remove a dark node.
    /// @param node The address of the node to remove.
    function _removeNode(address node) internal {
        darkNodes[node].active = false;
        // Remove the node from the nodeList array.
        for (uint256 i = 0; i < nodeList.length; i++) {
            if (nodeList[i] == node) {
                nodeList[i] = nodeList[nodeList.length - 1];
                nodeList.pop();
                break;
            }
        }
        emit NodeRemoved(node, block.timestamp);
    }

    /// @notice Returns the total number of active dark nodes.
    function getNodeCount() external view returns (uint256) {
        return nodeList.length;
    }
    
    /// @notice Fallback function to receive Ether.
    receive() external payable {}
}
