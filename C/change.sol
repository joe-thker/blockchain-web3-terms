// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title UTXOSimulator
/// @notice This contract simulates a basic UTXO model where users can deposit Ether,
/// spend UTXOs to send funds to a recipient, and receive change if the input exceeds the sent amount.
contract UTXOSimulator {
    uint256 public nextUTXOId;

    // A UTXO is represented by an ID, owner, value, and a spent flag.
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
    event Transaction(uint256 totalInput, uint256 sentAmount, uint256 change);

    /// @notice Allows a user to deposit Ether and create a new UTXO.
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        utxos[nextUTXOId] = UTXO({
            id: nextUTXOId,
            owner: msg.sender,
            value: msg.value,
            spent: false
        });
        emit UTXOCreated(nextUTXOId, msg.sender, msg.value);
        nextUTXOId++;
    }

    /// @notice Allows a user to send Ether by consuming one or more UTXOs.
    /// The function calculates the "change" if the total input exceeds the send amount.
    /// @param utxoIds An array of UTXO IDs to use as inputs.
    /// @param recipient The address of the recipient.
    /// @param amount The amount of Ether to send (in wei).
    function send(uint256[] calldata utxoIds, address recipient, uint256 amount) external {
        uint256 totalInput = 0;

        // Consume specified UTXOs.
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
        (bool sent, ) = recipient.call{value: amount}("");
        require(sent, "Transfer to recipient failed");

        // Calculate and return the change to the sender.
        uint256 change = totalInput - amount;
        if (change > 0) {
            utxos[nextUTXOId] = UTXO({
                id: nextUTXOId,
                owner: msg.sender,
                value: change,
                spent: false
            });
            emit UTXOCreated(nextUTXOId, msg.sender, change);
            nextUTXOId++;
        }

        emit Transaction(totalInput, amount, change);
    }
}
