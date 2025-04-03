// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ElectrumWallet
/// @notice A simple multi-signature wallet that requires a certain number of confirmations
/// from a set of owners to execute a transaction. This is a dynamic, optimized wallet contract.
contract ElectrumWallet is ReentrancyGuard {
    // List of wallet owners
    address[] public owners;
    // Number of required confirmations for a transaction to be executed
    uint256 public required;

    // Transaction structure
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }
    // Array of submitted transactions
    Transaction[] public transactions;

    // Mapping from transaction ID to owner confirmations
    mapping(uint256 => mapping(address => bool)) public confirmations;

    // --- Events ---
    event Deposit(address indexed sender, uint256 value);
    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed owner, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not an owner");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notConfirmed(uint256 _txId) {
        require(!confirmations[_txId][msg.sender], "Transaction already confirmed by this owner");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    /**
     * @notice Constructor initializes the wallet with a list of owners and the required number of confirmations.
     * @param _owners An array of owner addresses.
     * @param _required The number of confirmations required to execute a transaction.
     */
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number of owners");

        owners = _owners;
        required = _required;
    }

    // Allow the wallet to receive Ether.
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    /**
     * @notice Checks if an address is an owner.
     * @param _addr The address to check.
     * @return True if the address is an owner, false otherwise.
     */
    function isOwner(address _addr) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Submits a transaction for approval.
     * @param destination The address to which the transaction is directed.
     * @param value The amount of Ether (in wei) to send.
     * @param data The data payload for the transaction.
     * @return transactionId The index of the newly created transaction.
     */
    function submitTransaction(address destination, uint256 value, bytes calldata data)
        external
        onlyOwner
        returns (uint256 transactionId)
    {
        transactionId = transactions.length;
        transactions.push(Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        }));
        emit Submission(transactionId);
        confirmTransaction(transactionId);
    }

    /**
     * @notice Confirms a transaction. Each owner can confirm only once.
     * @param transactionId The ID of the transaction to confirm.
     */
    function confirmTransaction(uint256 transactionId)
        public
        onlyOwner
        txExists(transactionId)
        notConfirmed(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /**
     * @notice Executes a transaction if the required number of confirmations has been reached.
     * @param transactionId The ID of the transaction to execute.
     */
    function executeTransaction(uint256 transactionId)
        public
        nonReentrant
        txExists(transactionId)
        notExecuted(transactionId)
    {
        if (getConfirmationCount(transactionId) >= required) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            (bool success, ) = txn.destination.call{value: txn.value}(txn.data);
            if (success) {
                emit Execution(transactionId);
            } else {
                txn.executed = false;
                emit ExecutionFailure(transactionId);
            }
        }
    }

    /**
     * @notice Returns the number of confirmations for a transaction.
     * @param transactionId The ID of the transaction.
     * @return count The number of confirmations.
     */
    function getConfirmationCount(uint256 transactionId) public view returns (uint256 count) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
    }

    /**
     * @notice Retrieves the details of a transaction.
     * @param transactionId The ID of the transaction.
     * @return destination The destination address.
     * @return value The amount of Ether (in wei).
     * @return data The data payload.
     * @return executed Whether the transaction has been executed.
     */
    function getTransaction(uint256 transactionId)
        public
        view
        returns (address destination, uint256 value, bytes memory data, bool executed)
    {
        Transaction storage txn = transactions[transactionId];
        return (txn.destination, txn.value, txn.data, txn.executed);
    }
}
