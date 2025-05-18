// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TransactionTracker {
    mapping(bytes32 => bool) public usedHashes;

    event ActionExecuted(address indexed user, bytes32 txHash, uint256 value);

    function execute(bytes calldata data, uint256 nonce) external payable {
        bytes32 txHash = keccak256(abi.encodePacked(msg.sender, data, nonce, msg.value));
        require(!usedHashes[txHash], "Replay or duplicate tx");

        usedHashes[txHash] = true;

        // Example: decode and execute internal logic
        // (omitted for demo — assume call happens)

        emit ActionExecuted(msg.sender, txHash, msg.value);
    }
}
