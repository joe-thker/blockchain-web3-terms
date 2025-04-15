// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NodeExempt
 * @notice A node registration contract with an exemption list.
 *         Certain addresses can be exempt from paying the registration fee.
 *         The contract allows for fee management and fund withdrawals by the admin.
 */
contract NodeExempt {
    // Structure to store node details.
    struct NodeInfo {
        address owner;
        string nodeName;
        uint256 registeredAt;
        bool active;
    }

    mapping(uint256 => NodeInfo) public nodes;
    uint256 public nodeCount;
    
    // Registration fee required for node registration.
    uint256 public registrationFee;
    // Admin address.
    address public admin;
    
    // Mapping for fee exemption. If true, the address is exempt from the fee.
    mapping(address => bool) public isExempt;
    
    // Events for logging changes.
    event NodeRegistered(uint256 indexed nodeId, address indexed owner, string nodeName, uint256 registeredAt);
    event NodeDeregistered(uint256 indexed nodeId, address indexed owner);
    event RegistrationFeeUpdated(uint256 newFee);
    event AdminUpdated(address newAdmin);
    event ExemptionUpdated(address indexed account, bool isExempt);

    /**
     * @dev Constructor initializes the fee, admin, and sets the deployer as exempt.
     * @param _registrationFee The fee required to register a node.
     */
    constructor(uint256 _registrationFee) {
        admin = msg.sender;
        registrationFee = _registrationFee;
        // The admin (deployer) is exempt by default.
        isExempt[msg.sender] = true;
    }

    /**
     * @notice Modifier to restrict functions to admin only.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    /**
     * @notice Modifier to restrict functions to the owner of a node.
     * @param nodeId The ID of the node.
     */
    modifier onlyNodeOwner(uint256 nodeId) {
        require(nodes[nodeId].owner == msg.sender, "Caller is not the node owner");
        _;
    }

    /**
     * @notice Register a node by providing a node name. Fee is required unless sender is exempt.
     * @param nodeName The descriptive name for the node.
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

        // If sender overpays and is not exempt, refund the excess.
        if (!isExempt[msg.sender] && msg.value > registrationFee) {
            uint256 refund = msg.value - registrationFee;
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @notice Deregister (deactivate) a node.
     * @param nodeId The ID of the node.
     */
    function deregisterNode(uint256 nodeId) external onlyNodeOwner(nodeId) {
        require(nodes[nodeId].active, "Node is already inactive");
        nodes[nodeId].active = false;
        emit NodeDeregistered(nodeId, msg.sender);
    }

    /**
     * @notice Update the registration fee. Only admin can call.
     * @param newFee The new registration fee.
     */
    function updateRegistrationFee(uint256 newFee) external onlyAdmin {
        registrationFee = newFee;
        emit RegistrationFeeUpdated(newFee);
    }

    /**
     * @notice Update the admin address. Only admin can call.
     * @param newAdmin The new admin address.
     */
    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    /**
     * @notice Add or remove an address from the fee exemption list. Only admin can call.
     * @param account The address to update.
     * @param exempt True if the address should be exempt, false otherwise.
     */
    function updateExemption(address account, bool exempt) external onlyAdmin {
        isExempt[account] = exempt;
        emit ExemptionUpdated(account, exempt);
    }

    /**
     * @notice Withdraw collected fees. Only admin can call.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawFees(uint256 amount) external onlyAdmin {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(admin).transfer(amount);
    }

    /**
     * @dev Fallback function to accept incoming Ether.
     */
    receive() external payable {}
}
