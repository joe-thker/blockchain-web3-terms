// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title UTXOChangeAddressSimulator
/// @notice A simplified UTXO model simulator that supports a change address.
/// Users can deposit Ether to create UTXOs, then spend from them by specifying a recipient
/// and a change address for any leftover funds.
contract UTXOChangeAddressSimulator {
    uint256 public nextUTXOId;

    // A UTXO is represented by an ID, the owner's address, the value, and a spent flag.
    struct UTXO {
        uint256 id;
        address owner;
        uint256 value;
        bool spent;
    }

    // Mapping from UTXO ID to UTXO details.
    mapping(uint256 => UTXO) public utxos;

    // Events to log UTXO creation, spending, and transactions.
    event UTXOCreated(uint256 indexed id, address indexed owner, uint256 value);
    event UTXOSpent(uint256 indexed id);
    event TransactionExecuted(uint256 totalInput, uint256 sentAmount, uint256 change, address changeAddress);

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

    /// @notice Sends Ether using specified UTXOs and returns any change to a designated change address.
    /// @param utxoIds An array of UTXO IDs to use as inputs.
    /// @param recipient The address of the recipient.
    /// @param amount The amount to send (in wei).
    /// @param changeAddress The address to receive any leftover change.
    function send(
        uint256[] calldata utxoIds,
        address recipient,
        uint256 amount,
        address changeAddress
    ) external {
        uint256 totalInput = 0;

        // Sum up the total input and mark UTXOs as spent.
        for (uint256 i = 0; i < utxoIds.length; i++) {
            UTXO storage utxo = utxos[utxoIds[i]];
            require(!utxo.spent, "UTXO already spent");
            require(utxo.owner == msg.sender, "Not the owner of UTXO");
            totalInput += utxo.value;
            utxo.spent = true;
            emit UTXOSpent(utxo.id);
        }

        require(totalInput >= amount, "Insufficient funds");

        // Transfer the specified amount to the recipient.
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer to recipient failed");

        // Calculate change.
        uint256 change = totalInput - amount;

        // If there is change, create a new UTXO for the change at the designated change address.
        if (change > 0) {
            utxos[nextUTXOId] = UTXO({
                id: nextUTXOId,
                owner: changeAddress,
                value: change,
                spent: false
            });
            emit UTXOCreated(nextUTXOId, changeAddress, change);
            nextUTXOId++;
        }

        emit TransactionExecuted(totalInput, amount, change, changeAddress);
    }
}
