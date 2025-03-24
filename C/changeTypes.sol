// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title UTXOSimulatorWithChangeTypes
/// @notice This contract simulates a basic UTXO model with different types of change outputs.
/// Users can deposit Ether to create UTXOs and then spend them. Depending on the changeType parameter,
/// the contract will handle "change" in three ways:
/// 0 - Exact Payment: require input equals payment (no change).
/// 1 - Single Change Output: create one UTXO for all the change.
/// 2 - Multiple Change Outputs: split the change into two separate UTXOs.
contract UTXOSimulatorWithChangeTypes {
    uint256 public nextUTXOId;

    // A UTXO is represented by an ID, owner, value, and spent flag.
    struct UTXO {
        uint256 id;
        address owner;
        uint256 value;
        bool spent;
    }

    // Mapping from UTXO ID to UTXO details.
    mapping(uint256 => UTXO) public utxos;

    // Events for logging UTXO creation, spending, and transactions.
    event UTXOCreated(uint256 indexed id, address indexed owner, uint256 value);
    event UTXOSpent(uint256 indexed id);
    event TransactionExecuted(uint256 totalInput, uint256 sentAmount, uint256 change, uint8 changeType);

    /// @notice Deposits Ether and creates a new UTXO.
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be > 0");
        utxos[nextUTXOId] = UTXO({
            id: nextUTXOId,
            owner: msg.sender,
            value: msg.value,
            spent: false
        });
        emit UTXOCreated(nextUTXOId, msg.sender, msg.value);
        nextUTXOId++;
    }

    /// @notice Sends Ether using specified UTXOs. The function supports three types of change handling:
    /// changeType 0: Exact Payment (require totalInput == amount)
    /// changeType 1: Single Change Output (one UTXO for all change)
    /// changeType 2: Multiple Change Outputs (split change into two UTXOs)
    /// @param utxoIds An array of UTXO IDs to use as inputs.
    /// @param recipient The address of the recipient.
    /// @param amount The amount to send (in wei).
    /// @param changeType The change mode (0, 1, or 2).
    function send(
        uint256[] calldata utxoIds,
        address recipient,
        uint256 amount,
        uint8 changeType
    ) external {
        require(changeType < 3, "Invalid change type");
        uint256 totalInput = 0;

        // Mark and sum the selected UTXOs.
        for (uint256 i = 0; i < utxoIds.length; i++) {
            UTXO storage utxo = utxos[utxoIds[i]];
            require(!utxo.spent, "UTXO already spent");
            require(utxo.owner == msg.sender, "Not the owner of UTXO");
            totalInput += utxo.value;
            utxo.spent = true;
            emit UTXOSpent(utxo.id);
        }

        require(totalInput >= amount, "Insufficient funds");

        // Handle change based on the selected changeType.
        uint256 change = totalInput - amount;
        if (changeType == 0) {
            // Exact payment required.
            require(change == 0, "Exact payment required, no change allowed");
        } else if (changeType == 1) {
            // Single change output.
            if (change > 0) {
                // Create a new UTXO for the change.
                utxos[nextUTXOId] = UTXO({
                    id: nextUTXOId,
                    owner: msg.sender,
                    value: change,
                    spent: false
                });
                emit UTXOCreated(nextUTXOId, msg.sender, change);
                nextUTXOId++;
            }
        } else if (changeType == 2) {
            // Multiple change outputs: split change equally into two UTXOs.
            if (change > 0) {
                uint256 half1 = change / 2;
                uint256 half2 = change - half1; // In case of odd number, second gets the remainder.
                utxos[nextUTXOId] = UTXO({
                    id: nextUTXOId,
                    owner: msg.sender,
                    value: half1,
                    spent: false
                });
                emit UTXOCreated(nextUTXOId, msg.sender, half1);
                nextUTXOId++;
                utxos[nextUTXOId] = UTXO({
                    id: nextUTXOId,
                    owner: msg.sender,
                    value: half2,
                    spent: false
                });
                emit UTXOCreated(nextUTXOId, msg.sender, half2);
                nextUTXOId++;
            }
        }

        // Transfer the specified amount to the recipient.
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");

        emit TransactionExecuted(totalInput, amount, change, changeType);
    }
}
