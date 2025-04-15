// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Node
 * @notice A smart contract for node registration.
 *         Users can register nodes by paying a fee. Each node is recorded with its owner,
 *         name, registration time, and active status. The admin can update the fee,
 *         change admin, and withdraw collected fees.
 */
contract Node {
    // Structure to hold node data.
    struct NodeInfo {
        address owner;        // The address that registered the node.
        string nodeName;      // The node's descriptive name.
        uint256 registeredAt; // Timestamp of registration.
        bool active;          // Whether the node is active.
    }

    // Mapping of node IDs to node information.
    mapping(uint256 => NodeInfo) public nodes;
    // Total number of nodes; used to assign new node IDs.
    uint256 public nodeCount;
    
    // Registration fee required for node registration.
    uint256 public registrationFee;
    // Admin address that controls fee settings and can withdraw funds.
    address public admin;
    
    // Events for logging significant actions.
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
     * @notice Allows a user to register a node by paying the registration fee and providing a name.
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

        // Refund any excess funds.
        if (msg.value > registrationFee) {
            uint256 refund = msg.value - registrationFee;
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @notice Allows the node owner to deactivate their node.
     * @param nodeId The ID of the node to deregister.
     */
    function deregisterNode(uint256 nodeId) external {
        require(nodes[nodeId].owner == msg.sender, "Caller is not the node owner");
        require(nodes[nodeId].active, "Node is already inactive");
        nodes[nodeId].active = false;
        emit NodeDeregistered(nodeId, msg.sender);
    }

    /**
     * @notice Allows the admin to update the registration fee.
     * @param newFee The new registration fee.
     */
    function updateRegistrationFee(uint256 newFee) external {
        require(msg.sender == admin, "Only admin can update fee");
        registrationFee = newFee;
        emit RegistrationFeeUpdated(newFee);
    }

    /**
     * @notice Allows the admin to update the admin address.
     * @param newAdmin The address of the new admin.
     */
    function updateAdmin(address newAdmin) external {
        require(msg.sender == admin, "Only admin can update admin address");
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    /**
     * @notice Allows the admin to withdraw collected fees.
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
