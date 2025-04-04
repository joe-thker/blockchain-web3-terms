// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EthereumTransactionTracker {
    struct Transaction {
        address from;
        address to;
        uint256 value;
        uint256 timestamp;
        string note;
    }

    Transaction[] public transactions;

    event TransactionLogged(address indexed from, address indexed to, uint256 value, string note);

    // Send ETH and log the transaction
    function sendEther(address payable recipient, string calldata note) external payable {
        require(msg.value > 0, "Send ETH to record transaction");
        require(recipient != address(0), "Invalid recipient");

        (bool sent, ) = recipient.call{value: msg.value}("");
        require(sent, "Failed to send ETH");

        transactions.push(Transaction({
            from: msg.sender,
            to: recipient,
            value: msg.value,
            timestamp: block.timestamp,
            note: note
        }));

        emit TransactionLogged(msg.sender, recipient, msg.value, note);
    }

    // Get total transactions count
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    // Get a transaction by index
    function getTransaction(uint256 index) external view returns (Transaction memory) {
        require(index < transactions.length, "Index out of bounds");
        return transactions[index];
    }

    receive() external payable {
        revert("Use sendEther function");
    }
}
