// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AdvancedNode
 * @notice An advanced node registration contract that extends the basic functionality.
 *         In this version, node owners can update their node's name. Administrative functions
 *         such as fee management and fund withdrawal remain available.
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
     * @notice Modifier to restrict access to admin only.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    /**
     * @notice Modifier to restrict access to the owner of a specific node.
     * @param nodeId The ID of the node.
     */
    modifier onlyNodeOwner(uint256 nodeId) {
        require(nodes[nodeId].owner == msg.sender, "Caller is not the node owner");
        _;
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
     * @notice Allow a node owner to update the node's name.
     * @param nodeId The ID of the node to update.
     * @param newName The new name for the node.
     */
    function updateNodeName(uint256 nodeId, string calldata newName) external onlyNodeOwner(nodeId) {
        require(nodes[nodeId].active, "Node is inactive");
        string memory oldName = nodes[nodeId].nodeName;
        nodes[nodeId].nodeName = newName;
        emit NodeUpdated(nodeId, oldName, newName);
    }

    /**
     * @notice Deregister (deactivate) a node.
     * @param nodeId The ID of the node to deregister.
     */
    function deregisterNode(uint256 nodeId) external onlyNodeOwner(nodeId) {
        require(nodes[nodeId].active, "Node is already inactive");
        nodes[nodeId].active = false;
        emit NodeDeregistered(nodeId, msg.sender);
    }

    /**
     * @notice Update the registration fee. Only admin can execute.
     * @param newFee The new registration fee.
     */
    function updateRegistrationFee(uint256 newFee) external onlyAdmin {
        registrationFee = newFee;
        emit RegistrationFeeUpdated(newFee);
    }

    /**
     * @notice Update the admin address. Only current admin can execute.
     * @param newAdmin The new admin address.
     */
    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    /**
     * @notice Withdraw collected fees. Only admin can execute.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawFees(uint256 amount) external onlyAdmin {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(admin).transfer(amount);
    }
    
    /**
     * @dev Receive function to allow direct Ether transfers.
     */
    receive() external payable {}
}
