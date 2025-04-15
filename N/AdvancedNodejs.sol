// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AdvancedNode
 * @notice An advanced node registration contract that extends basic functionality.
 *         Node owners can update their node’s name, in addition to registering and deregistering nodes.
 */
contract AdvancedNode {
    // Structure to store node details.
    struct NodeInfo {
        address owner;        // Node owner.
        string nodeName;      // Node descriptive name.
        uint256 registeredAt; // Timestamp of registration.
        bool active;          // Node status.
    }

    mapping(uint256 => NodeInfo) public nodes;
    uint256 public nodeCount;
    
    uint256 public registrationFee;
    address public admin;
    
    // Events for logging actions.
    event NodeRegistered(uint256 indexed nodeId, address indexed owner, string nodeName, uint256 registeredAt);
    event NodeUpdated(uint256 indexed nodeId, string oldName, string newName);
    event NodeDeregistered(uint256 indexed nodeId, address indexed owner);
    event RegistrationFeeUpdated(uint256 newFee);
    event AdminUpdated(address newAdmin);

    /**
     * @dev Constructor initializes registration fee and admin.
     * @param _registrationFee The fee required to register a node.
     */
    constructor(uint256 _registrationFee) {
        admin = msg.sender;
        registrationFee = _registrationFee;
    }

    /**
     * @notice Register a node with a given name by paying the registration fee.
     * @param nodeName The node's descriptive name.
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

        // Refund any excess payment.
        if (msg.value > registrationFee) {
            uint256 refund = msg.value - registrationFee;
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @notice Allows a node owner to update the node's name.
     * @param nodeId The ID of the node to update.
     * @param newName The new name for the node.
     */
    function updateNodeName(uint256 nodeId, string calldata newName) external {
        require(nodes[nodeId].owner == msg.sender, "Caller is not the node owner");
        require(nodes[nodeId].active, "Node is inactive");
        string memory oldName = nodes[nodeId].nodeName;
        nodes[nodeId].nodeName = newName;
        emit NodeUpdated(nodeId, oldName, newName);
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
     * @dev Receive function to allow direct Ether transfers.
     */
    receive() external payable {}
}
