// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Encrypted Credit Scores using FHE simulation
/// @notice Stores encrypted scores without exposing raw score

contract FHECreditScore {
    mapping(address => bytes32) public encryptedScores;

    event ScoreSubmitted(address indexed user, bytes32 cipher);

    function submitEncryptedScore(bytes32 encryptedScore) external {
        encryptedScores[msg.sender] = encryptedScore;
        emit ScoreSubmitted(msg.sender, encryptedScore);
    }

    function getEncryptedScore(address user) external view returns (bytes32) {
        return encryptedScores[user];
    }
}
