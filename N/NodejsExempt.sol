// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NodeExempt
 * @notice A node registration contract with a fee exemption list.
 *         Addresses marked as exempt can register nodes without paying a fee.
 *         Admin functions allow fee updates, exemption management, and fund withdrawals.
 */
contract NodeExempt {
    // Structure to store node details.
    struct NodeInfo {
        address owner;        // Owner of the node.
        string nodeName;      // Descriptive name of the node.
        uint256 registeredAt; // Registration timestamp.
        bool active;          // Node status.
    }

    mapping(uint256 => NodeInfo) public nodes;
    uint256 public nodeCount;
    
    // Registration fee required for node registration (applies only to non-exempt addresses).
    uint256 public registrationFee;
    // Admin address.
    address public admin;
    
    // Mapping for fee exemption; true if the address is exempt from paying the fee.
    mapping(address => bool) public isExempt;
    
    // Events for logging changes.
    event NodeRegistered(uint256 indexed nodeId, address indexed owner, string nodeName, uint256 registeredAt);
    event NodeDeregistered(uint256 indexed nodeId, address indexed owner);
    event RegistrationFeeUpdated(uint256 newFee);
    event AdminUpdated(address newAdmin);
    event ExemptionUpdated(address indexed account, bool isExempt);

    /**
     * @dev Constructor initializes the registration fee and admin.
     * @param _registrationFee The fee required to register a node.
     */
    constructor(uint256 _registrationFee) {
        admin = msg.sender;
        registrationFee = _registrationFee;
        // The admin (deployer) is exempt by default.
        isExempt[msg.sender] = true;
    }

    /**
     * @notice Register a node by providing a node name.
     *         Non-exempt addresses must pay the registration fee.
     * @param nodeName The descriptive name of the node.
     */
    function registerNode(string calldata nodeName) external payable {
        // If the sender is not exempt, require the fee.
        if (!isExempt[msg.sender]) {
            require(msg.value >= registrationFee, "Insufficient fee sent");
        }

        uint256 nodeId = nodeCount;
        nodes[nodeId] = NodeInfo({
            owner: msg.sender,
            nodeName: nodeName,
            registeredAt: block.timestamp,
            active: true
        });
        nodeCount++;

        emit NodeRegistered(nodeId, msg.sender, nodeName, block.timestamp);

        // Refund any excess fee to non-exempt addresses.
        if (!isExempt[msg.sender] && msg.value > registrationFee) {
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
     * @param newAdmin The new admin address.
     */
    function updateAdmin(address newAdmin) external {
        require(msg.sender == admin, "Only admin can update admin address");
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    /**
     * @notice Add or remove an address from the exemption list.
     *         Only the admin can update exemptions.
     * @param account The address to update.
     * @param exempt True to mark the address as exempt, false otherwise.
     */
    function updateExemption(address account, bool exempt) external {
        require(msg.sender == admin, "Only admin can update exemption list");
        isExempt[account] = exempt;
        emit ExemptionUpdated(account, exempt);
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
     * @dev Fallback function to accept incoming Ether.
     */
    receive() external payable {}
}
