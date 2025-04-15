// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BasicNode
 * @notice A simple node registration contract.
 *         Users can register their nodes by paying a fee and providing a node name.
 *         The contract records basic node information and allows the admin to manage fees.
 */
contract BasicNode {
    // Structure to hold node information.
    struct NodeInfo {
        address owner;        // Owner of the node.
        string nodeName;      // Descriptive name for the node.
        uint256 registeredAt; // Timestamp when the node was registered.
        bool active;          // Whether the node is active.
    }

    // Mapping of node IDs to node information.
    mapping(uint256 => NodeInfo) public nodes;
    // Counter for generating node IDs.
    uint256 public nodeCount;
    
    // Registration fee required for node registration.
    uint256 public registrationFee;
    // Admin address with permission to update fee and withdraw funds.
    address public admin;
    
    // Events for logging.
    event NodeRegistered(uint256 indexed nodeId, address indexed owner, string nodeName, uint256 registeredAt);
    event NodeDeregistered(uint256 indexed nodeId, address indexed owner);
    event RegistrationFeeUpdated(uint256 newFee);
    event AdminUpdated(address newAdmin);

    /**
     * @dev Constructor sets the initial registration fee and admin.
     * @param _registrationFee The fee required to register a node.
     */
    constructor(uint256 _registrationFee) {
        admin = msg.sender;
        registrationFee = _registrationFee;
    }

    /**
     * @notice Register a node by providing a node name and paying the registration fee.
     * @param nodeName The descriptive name of the node.
     */
    function registerNode(string calldata nodeName) external payable {
        require(msg.value >= registrationFee, "Insufficient fee sent");

        uint256 nodeId = nodeCount;
        nodes[nodeId] = NodeInfo({
            owner: msg.sender,
            nodeName: nodeName,
            registeredAt: block.timestamp,
            active: true
        });
        nodeCount++;

        emit NodeRegistered(nodeId, msg.sender, nodeName, block.timestamp);

        // Refund any excess fee.
        if (msg.value > registrationFee) {
            uint256 refund = msg.value - registrationFee;
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @notice Deregister (deactivate) a node.
     * @param nodeId The ID of the node to deregister.
     */
    function deregisterNode(uint256 nodeId) external {
        require(nodes[nodeId].owner == msg.sender, "Caller is not the node owner");
        require(nodes[nodeId].active, "Node is already inactive");
        nodes[nodeId].active = false;
        emit NodeDeregistered(nodeId, msg.sender);
    }

    /**
     * @notice Update the registration fee. Only admin can call.
     * @param newFee The new registration fee.
     */
    function updateRegistrationFee(uint256 newFee) external {
        require(msg.sender == admin, "Only admin can update fee");
        registrationFee = newFee;
        emit RegistrationFeeUpdated(newFee);
    }

    /**
     * @notice Update the admin address. Only admin can call.
     * @param newAdmin The address of the new admin.
     */
    function updateAdmin(address newAdmin) external {
        require(msg.sender == admin, "Only admin can update admin address");
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    /**
     * @notice Withdraw collected fees. Only admin can call.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawFees(uint256 amount) external {
        require(msg.sender == admin, "Only admin can withdraw fees");
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(admin).transfer(amount);
    }

    /**
     * @dev Fallback function to accept Ether.
     */
    receive() external payable {}
}
