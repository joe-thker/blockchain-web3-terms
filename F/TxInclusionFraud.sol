// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TxInclusionFraud {
    mapping(bytes32 => bool) public committedTxs;
    mapping(bytes32 => bool) public challengedTxs;

    event TxCommitted(bytes32 txHash);
    event FraudProof(bytes32 txHash, address challenger);

    function commitTx(bytes calldata txData) external {
        bytes32 hash = keccak256(txData);
        committedTxs[hash] = true;
        emit TxCommitted(hash);
    }

    function proveOmission(bytes calldata txData) external {
        bytes32 hash = keccak256(txData);
        require(!committedTxs[hash], "Tx already committed");
        challengedTxs[hash] = true;
        emit FraudProof(hash, msg.sender);
    }
}
