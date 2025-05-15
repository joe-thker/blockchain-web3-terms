// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title HouseCommitteeVault - Simulates U.S. House Committee control over treasury spending

contract HouseCommitteeVault {
    address public chairperson;
    mapping(address => bool) public committeeMembers;
    mapping(address => bool) public auditors;

    struct Proposal {
        address payable recipient;
        uint256 amount;
        string description;
        uint256 votes;
        bool executed;
        uint256 deadline;
        mapping(address => bool) hasVoted;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    modifier onlyChair() {
        require(msg.sender == chairperson, "Not chairperson");
        _;
    }

    modifier onlyCommittee() {
        require(committeeMembers[msg.sender], "Not a committee member");
        _;
    }

    modifier onlyAuditor() {
        require(auditors[msg.sender], "Not an auditor");
        _;
    }

    event Deposit(address indexed from, uint256 amount);
    event ProposalCreated(uint256 indexed id, address recipient, uint256 amount);
    event Voted(uint256 indexed id, address voter);
    event Executed(uint256 indexed id, address recipient, uint256 amount);

    constructor(address[] memory _committee, address[] memory _auditors) {
        chairperson = msg.sender;
        for (uint i = 0; i < _committee.length; i++) {
            committeeMembers[_committee[i]] = true;
        }
        for (uint i = 0; i < _auditors.length; i++) {
            auditors[_auditors[i]] = true;
        }
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function createProposal(address payable recipient, uint256 amount, string calldata description) external onlyCommittee {
        require(address(this).balance >= amount, "Insufficient vault funds");

        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.recipient = recipient;
        p.amount = amount;
        p.description = description;
        p.deadline = block.timestamp + 3 days;

        emit ProposalCreated(proposalCount, recipient, amount);
    }

    function voteOnProposal(uint256 proposalId) external onlyCommittee {
        Proposal storage p = proposals[proposalId];
        require(!p.executed, "Already executed");
        require(!p.hasVoted[msg.sender], "Already voted");
        require(block.timestamp <= p.deadline, "Voting closed");

        p.hasVoted[msg.sender] = true;
        p.votes++;

        emit Voted(proposalId, msg.sender);
    }

    function executeProposal(uint256 proposalId) external onlyChair {
        Proposal storage p = proposals[proposalId];
        require(!p.executed, "Already executed");
        require(p.votes >= 2, "Not enough votes");
        require(block.timestamp > p.deadline, "Voting still open");

        p.executed = true;
        (bool success, ) = p.recipient.call{value: p.amount}("");
        require(success, "Transfer failed");

        emit Executed(proposalId, p.recipient, p.amount);
    }

    function auditTreasury() external view onlyAuditor returns (uint256 balance, uint256 activeProposals) {
        balance = address(this).balance;
        for (uint i = 1; i <= proposalCount; i++) {
            if (!proposals[i].executed && block.timestamp <= proposals[i].deadline) {
                activeProposals++;
            }
        }
    }
}
