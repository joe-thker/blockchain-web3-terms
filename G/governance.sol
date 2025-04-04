// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TokenGovernance {
    mapping(address => uint256) public tokenBalance;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    constructor() {
        tokenBalance[msg.sender] = 1000 * 1e18; // simple starter
    }

    function createProposal(string memory description) external returns (uint256) {
        proposals[proposalCount] = Proposal(description, 0, 0, false);
        return proposalCount++;
    }

    function vote(uint256 proposalId, bool support) external {
        uint256 weight = tokenBalance[msg.sender];
        require(weight > 0, "No tokens");

        Proposal storage p = proposals[proposalId];
        require(!p.executed, "Already executed");

        if (support) {
            p.votesFor += weight;
        } else {
            p.votesAgainst += weight;
        }
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(!p.executed, "Already executed");
        require(p.votesFor > p.votesAgainst, "Not passed");

        p.executed = true;
        // apply logic here (external call, state change, etc.)
    }
}
