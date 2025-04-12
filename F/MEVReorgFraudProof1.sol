// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MessageFraudProof {
    mapping(bytes32 => bool) public claimedMessages;

    event MessageClaimed(bytes32 messageHash, address claimer);
    event MessageFraud(bytes32 messageHash, address challenger);

    function claimMessage(bytes32 messageHash, bytes calldata proof) external {
        require(!claimedMessages[messageHash], "Already claimed");

        if (!verifyProof(messageHash, proof)) {
            emit MessageFraud(messageHash, msg.sender);
            return;
        }

        claimedMessages[messageHash] = true;
        emit MessageClaimed(messageHash, msg.sender);
    }

    function verifyProof(bytes32, bytes calldata) internal pure returns (bool) {
        return true; // replace with real bridge Merkle proof
    }
}
