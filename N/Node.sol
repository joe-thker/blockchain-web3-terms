// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Node
 * @notice A smart contract that enables node registration for a decentralized network.
 *         Users can register nodes by paying a fee, and the contract maintains a list
 *         of registered nodes along with basic node information. The administrator can
 *         update the registration fee, change the admin address, and withdraw collected fees.
 */
contract Node {
    // Structure to hold node information.
    struct NodeInfo {
        address owner;       // Address of the node owner.
        string nodeName;     // A descriptive name for the node.
        uint256 registeredAt;// Timestamp when the node was registered.
        bool active;         // Status of the node (active/inactive).
    }

    // Mapping to store node information by node ID.
    mapping(uint256 => NodeInfo) public nodes;
    
    // Total count of registered nodes (used as node IDs).
    uint256 public nodeCount;
    
    // Fee required to register a node.
    uint256 public registrationFee;
    
    // Admin address that can manage fee settings and withdraw fees.
    address public admin;
    
    // Events for logging important actions.
    event NodeRegistered(uint256 indexed nodeId, address indexed owner, string nodeName, uint256 registeredAt);
    event NodeDeregistered(uint256 indexed nodeId, address indexed owner);
    event RegistrationFeeUpdated(uint256 newFee);
    event AdminUpdated(address newAdmin);

    /**
     * @dev Constructor initializes the contract with a given registration fee.
     * @param _registrationFee The fee required to register a node.
     */
    constructor(uint256 _registrationFee) {
        admin = msg.sender;
        registrationFee = _registrationFee;
    }

    /**
     * @dev Modifier to restrict functions to only the admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    /**
     * @dev Modifier to restrict functions to the owner of a specific node.
     * @param nodeId The ID of the node.
     */
    modifier onlyNodeOwner(uint256 nodeId) {
        require(nodes[nodeId].owner == msg.sender, "Caller is not the node owner");
        _;
    }

    /**
     * @notice Allows a user to register a node by providing a node name and paying the registration fee.
     * @param nodeName A descriptive name for the node.
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

        // Refund any excess funds if the sender overpays.
        if (msg.value > registrationFee) {
            uint256 refund = msg.value - registrationFee;
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @notice Allows a node owner to deregister (deactivate) their node.
     * @param nodeId The ID of the node to deregister.
     */
    function deregisterNode(uint256 nodeId) external onlyNodeOwner(nodeId) {
        require(nodes[nodeId].active, "Node is already inactive");
        nodes[nodeId].active = false;
        emit NodeDeregistered(nodeId, msg.sender);
    }

    /**
     * @notice Allows the admin to update the registration fee.
     * @param newFee The new registration fee.
     */
    function updateRegistrationFee(uint256 newFee) external onlyAdmin {
        registrationFee = newFee;
        emit RegistrationFeeUpdated(newFee);
    }

    /**
     * @notice Allows the admin to update the admin address.
     * @param newAdmin The address of the new admin.
     */
    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    /**
     * @notice Allows the admin to withdraw a specified amount of collected fees.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawFees(uint256 amount) external onlyAdmin {
        require(address(this).balance >= amount, "Insufficient funds in contract");
        payable(admin).transfer(amount);
    }

    /**
     * @dev Fallback function to allow the contract to receive Ether.
     */
    receive() external payable {}
}
