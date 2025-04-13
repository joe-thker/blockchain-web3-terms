// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFutoToken {
    function balanceOf(address account) external view returns (uint256);
}

contract FutoVoting {
    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool open;
    }

    IFutoToken public token;
    Proposal[] public proposals;

    mapping(uint256 => mapping(address => bool)) public hasVoted;

    constructor(address tokenAddress) {
        token = IFutoToken(tokenAddress);
    }

    function createProposal(string memory description) external {
        proposals.push(Proposal(description, 0, 0, true));
    }

    function vote(uint256 proposalId, bool support) external {
        require(proposals[proposalId].open, "Voting closed");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 weight = token.balanceOf(msg.sender);
        require(weight > 0, "No tokens");

        if (support) {
            proposals[proposalId].votesFor += weight;
        } else {
            proposals[proposalId].votesAgainst += weight;
        }

        hasVoted[proposalId][msg.sender] = true;
    }

    function closeProposal(uint256 proposalId) external {
        proposals[proposalId].open = false;
    }
}
