// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NickSzaboDAO
/// @notice A simple DAO contract to manage membership and propose votes related to Nick Szabo's legacy.
contract NickSzaboDAO {
    address public chair;
    mapping(address => bool) public members;

    event MemberAdded(address member);
    event MemberRemoved(address member);
    event ProposalSubmitted(uint256 proposalId, string description);
    event VoteCast(uint256 proposalId, address member, bool support);

    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }
    Proposal[] public proposals;

    modifier onlyChair() {
        require(msg.sender == chair, "Not chair");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Not a member");
        _;
    }

    constructor() {
        chair = msg.sender;
        members[msg.sender] = true;
    }

    /// @notice Chair can add a new member.
    function addMember(address addr) external onlyChair {
        members[addr] = true;
        emit MemberAdded(addr);
    }

    /// @notice Chair can remove a member.
    function removeMember(address addr) external onlyChair {
        members[addr] = false;
        emit MemberRemoved(addr);
    }

    /// @notice Any member can submit a proposal.
    function submitProposal(string calldata description) external onlyMember {
        proposals.push(Proposal(description, 0, 0, false));
        emit ProposalSubmitted(proposals.length - 1, description);
    }

    /// @notice Members can vote on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param support True if voting in favor, false if against.
    function vote(uint256 proposalId, bool support) external onlyMember {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit VoteCast(proposalId, msg.sender, support);
    }

    /// @notice Chair can execute a proposal (for demo purposes, just marks it executed).
    function executeProposal(uint256 proposalId) external onlyChair {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Already executed");
        proposal.executed = true;
    }
}
