// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Confirmation is a multi-signature contract that requires a number of owner confirmations
/// before a transaction can be executed. It is dynamic, optimized, and secure.
contract Confirmation is ReentrancyGuard {
    // List of owners
    address[] public owners;
    // Quick lookup to check if an address is an owner.
    mapping(address => bool) public isOwner;
    // The number of confirmations required for executing a transaction.
    uint256 public requiredConfirmations;
    
    // Transaction structure represents a proposal.
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }
    
    // Array of all submitted transactions.
    Transaction[] public transactions;
    
    // Mapping: transaction ID => owner address => confirmation status.
    mapping(uint256 => mapping(address => bool)) public confirmations;
    
    // --- Events ---
    event OwnerAdded(address owner);
    event OwnerRemoved(address owner);
    event RequirementChanged(uint256 requiredConfirmations);
    event TransactionSubmitted(uint256 indexed txIndex, address indexed destination, uint256 value, bytes data);
    event TransactionConfirmed(uint256 indexed txIndex, address indexed owner);
    event TransactionRevoked(uint256 indexed txIndex, address indexed owner);
    event TransactionExecuted(uint256 indexed txIndex);
    event TransactionExecutionFailed(uint256 indexed txIndex);
    
    // --- Modifiers ---
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }
    
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }
    
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }
    
    modifier notConfirmed(uint256 _txIndex) {
        require(!confirmations[_txIndex][msg.sender], "Transaction already confirmed");
        _;
    }
    
    /// @notice Constructor sets the initial owners and the required number of confirmations.
    /// @param _owners Array of owner addresses.
    /// @param _requiredConfirmations Number of confirmations required to execute a transaction.
    constructor(address[] memory _owners, uint256 _requiredConfirmations) {
        require(_owners.length > 0, "Owners required");
        require(
            _requiredConfirmations > 0 && _requiredConfirmations <= _owners.length,
            "Invalid number of required confirmations"
        );
        for (uint256 i = 0; i < _owners.length; i++) {
            address ownerAddr = _owners[i];
            require(ownerAddr != address(0), "Invalid owner address");
            require(!isOwner[ownerAddr], "Owner not unique");
            
            isOwner[ownerAddr] = true;
            owners.push(ownerAddr);
            emit OwnerAdded(ownerAddr);
        }
        requiredConfirmations = _requiredConfirmations;
        emit RequirementChanged(_requiredConfirmations);
    }
    
    /// @notice Allows an owner to submit a new transaction (proposal).
    /// @param _destination The target address of the transaction.
    /// @param _value The Ether value to send.
    /// @param _data The data payload of the transaction.
    /// @return txIndex The index (ID) of the submitted transaction.
    function submitTransaction(address _destination, uint256 _value, bytes memory _data)
        public
        onlyOwner
        returns (uint256 txIndex)
    {
        txIndex = transactions.length;
        transactions.push(Transaction({
            destination: _destination,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));
        emit TransactionSubmitted(txIndex, _destination, _value, _data);
    }
    
    /// @notice Allows an owner to confirm a transaction.
    /// @param _txIndex The index (ID) of the transaction to confirm.
    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        confirmations[_txIndex][msg.sender] = true;
        transactions[_txIndex].numConfirmations += 1;
        emit TransactionConfirmed(_txIndex, msg.sender);
    }
    
    /// @notice Allows an owner to revoke their confirmation for a transaction.
    /// @param _txIndex The index (ID) of the transaction to revoke confirmation from.
    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        require(confirmations[_txIndex][msg.sender], "Transaction not confirmed");
        confirmations[_txIndex][msg.sender] = false;
        transactions[_txIndex].numConfirmations -= 1;
        emit TransactionRevoked(_txIndex, msg.sender);
    }
    
    /// @notice Executes a transaction if it has received enough confirmations.
    /// @param _txIndex The index (ID) of the transaction to execute.
    function executeTransaction(uint256 _txIndex)
        public
        nonReentrant
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage txn = transactions[_txIndex];
        require(txn.numConfirmations >= requiredConfirmations, "Insufficient confirmations");
        
        txn.executed = true;
        (bool success, ) = txn.destination.call{value: txn.value}(txn.data);
        if (success) {
            emit TransactionExecuted(_txIndex);
        } else {
            txn.executed = false;
            emit TransactionExecutionFailed(_txIndex);
        }
    }
    
    /// @notice Fallback function to receive Ether.
    receive() external payable {}
}
