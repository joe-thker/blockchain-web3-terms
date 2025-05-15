// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title UTXOSimulator - Emulates UTXO model in account-based Ethereum
contract UTXOSimulator {
    struct UTXO {
        address owner;
        uint256 amount;
        bool spent;
    }

    uint256 public utxoCount;
    mapping(uint256 => UTXO) public utxos;

    event UTXOCreated(uint256 indexed id, address indexed owner, uint256 amount);
    event UTXOSpent(uint256 indexed id, address indexed to, uint256 amount);

    /// Deposit ETH and create UTXO
    function createUTXO() external payable {
        require(msg.value > 0, "No ETH sent");

        utxos[utxoCount] = UTXO(msg.sender, msg.value, false);
        emit UTXOCreated(utxoCount, msg.sender, msg.value);
        utxoCount++;
    }

    /// Spend one UTXO to send funds to someone
    function spendUTXO(uint256 id, address payable to) external {
        UTXO storage utxo = utxos[id];
        require(!utxo.spent, "UTXO already spent");
        require(utxo.owner == msg.sender, "Not your UTXO");

        utxo.spent = true;
        to.transfer(utxo.amount);

        emit UTXOSpent(id, to, utxo.amount);
    }

    /// View total balance held in unspent UTXOs
    function getUnspentBalance(address user) external view returns (uint256 total) {
        for (uint256 i = 0; i < utxoCount; i++) {
            UTXO storage u = utxos[i];
            if (u.owner == user && !u.spent) {
                total += u.amount;
            }
        }
    }

    receive() external payable {}
}
