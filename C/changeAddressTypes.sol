// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title UTXOChangeAddressTypes
/// @notice Simulates a UTXO model with multiple methods for returning change to a designated address.
/// The contract supports three change modes:
/// 0 - Self-Change: Return all change to the sender.
/// 1 - Single External Change Address: Return all change to a specified address.
/// 2 - Split Change: Divide the change equally between two specified addresses.
contract UTXOChangeAddressTypes {
    uint256 public nextUTXOId;

    // Represents an unspent transaction output (UTXO).
    struct UTXO {
        uint256 id;
        address owner;
        uint256 value;
        bool spent;
    }

    // Mapping from UTXO ID to UTXO details.
    mapping(uint256 => UTXO) public utxos;

    // Events for logging UTXO creation, spending, and transaction execution.
    event UTXOCreated(uint256 indexed id, address indexed owner, uint256 value);
    event UTXOSpent(uint256 indexed id);
    event TransactionExecuted(uint256 totalInput, uint256 sentAmount, uint256 change, uint8 changeMode, address[] changeAddresses);

    /// @notice Deposits Ether to create a new UTXO.
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

    /// @notice Sends Ether using specified UTXOs and returns change according to the selected mode.
    /// @param utxoIds An array of UTXO IDs to be spent.
    /// @param recipient The address to receive the payment.
    /// @param amount The amount (in wei) to send to the recipient.
    /// @param changeMode The change mode: 0 (self-change), 1 (single external), 2 (split change).
    /// @param changeAddresses An array of addresses for receiving change:
    ///        - For mode 0, this is ignored.
    ///        - For mode 1, it must contain 1 address.
    ///        - For mode 2, it must contain 2 addresses.
    function send(
        uint256[] calldata utxoIds,
        address recipient,
        uint256 amount,
        uint8 changeMode,
        address[] calldata changeAddresses
    ) external {
        require(changeMode < 3, "Invalid change mode");
        if (changeMode == 1) {
            require(changeAddresses.length == 1, "Mode 1 requires 1 change address");
        } else if (changeMode == 2) {
            require(changeAddresses.length == 2, "Mode 2 requires 2 change addresses");
        }

        uint256 totalInput = 0;
        // Sum inputs and mark UTXOs as spent.
        for (uint256 i = 0; i < utxoIds.length; i++) {
            UTXO storage utxo = utxos[utxoIds[i]];
            require(!utxo.spent, "UTXO already spent");
            require(utxo.owner == msg.sender, "Not owner of UTXO");
            totalInput += utxo.value;
            utxo.spent = true;
            emit UTXOSpent(utxo.id);
        }

        require(totalInput >= amount, "Insufficient funds");

        // Transfer the specified amount to the recipient.
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer to recipient failed");

        uint256 change = totalInput - amount;
        address[] memory finalChangeAddresses;

        if (change > 0) {
            if (changeMode == 0) {
                // Mode 0: Self-Change – return all change to msg.sender.
                utxos[nextUTXOId] = UTXO({
                    id: nextUTXOId,
                    owner: msg.sender,
                    value: change,
                    spent: false
                });
                finalChangeAddresses = new address[](1);
                finalChangeAddresses[0] = msg.sender;
                emit UTXOCreated(nextUTXOId, msg.sender, change);
                nextUTXOId++;
            } else if (changeMode == 1) {
                // Mode 1: Single External Change Address – return all change to changeAddresses[0].
                utxos[nextUTXOId] = UTXO({
                    id: nextUTXOId,
                    owner: changeAddresses[0],
                    value: change,
                    spent: false
                });
                finalChangeAddresses = new address[](1);
                finalChangeAddresses[0] = changeAddresses[0];
                emit UTXOCreated(nextUTXOId, changeAddresses[0], change);
                nextUTXOId++;
            } else if (changeMode == 2) {
                // Mode 2: Split Change – divide change equally between two addresses.
                uint256 half1 = change / 2;
                uint256 half2 = change - half1;
                finalChangeAddresses = new address[](2);
                finalChangeAddresses[0] = changeAddresses[0];
                finalChangeAddresses[1] = changeAddresses[1];
                utxos[nextUTXOId] = UTXO({
                    id: nextUTXOId,
                    owner: changeAddresses[0],
                    value: half1,
                    spent: false
                });
                emit UTXOCreated(nextUTXOId, changeAddresses[0], half1);
                nextUTXOId++;
                utxos[nextUTXOId] = UTXO({
                    id: nextUTXOId,
                    owner: changeAddresses[1],
                    value: half2,
                    spent: false
                });
                emit UTXOCreated(nextUTXOId, changeAddresses[1], half2);
                nextUTXOId++;
            }
        } else {
            finalChangeAddresses = new address[](0);
        }

        emit TransactionExecuted(totalInput, amount, change, changeMode, finalChangeAddresses);
    }
}
