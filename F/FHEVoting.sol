// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FHE Voting Simulation
/// @notice Votes are stored encrypted (off-chain FHE encryption assumed)

contract FHEVoting {
    address public admin;

    struct Vote {
        bytes32 encryptedVote; // Simulated encrypted "0" or "1"
        bool submitted;
    }

    mapping(address => Vote) public votes;

    event EncryptedVoteSubmitted(address voter, bytes32 cipher);

    constructor() {
        admin = msg.sender;
    }

    function submitEncryptedVote(bytes32 encryptedVote) external {
        require(!votes[msg.sender].submitted, "Already voted");
        votes[msg.sender] = Vote(encryptedVote, true);
        emit EncryptedVoteSubmitted(msg.sender, encryptedVote);
    }

    function getEncryptedVote(address voter) external view returns (bytes32) {
        require(votes[voter].submitted, "No vote");
        return votes[voter].encryptedVote;
    }
}
