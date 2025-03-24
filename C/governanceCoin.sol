// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GovernanceCoin
/// @notice An ERC20 token representing a governance coin with a simple voting mechanism.
contract GovernanceCoin is ERC20, Ownable {
    uint256 public proposalCount;

    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCount;
        mapping(address => bool) voted;
        bool executed;
    }
    
    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed proposalId, string description);
    event Voted(uint256 indexed proposalId, address indexed voter);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(uint256 initialSupply) ERC20("GovernanceCoin", "GOV") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Creates a new proposal.
    /// @param description The proposal description.
    function createProposal(string calldata description) external onlyOwner {
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.description = description;
        newProposal.voteCount = 0;
        newProposal.executed = false;
        emit ProposalCreated(proposalCount, description);
        proposalCount++;
    }

    /// @notice Votes on a proposal. Each token holder can vote once per proposal.
    /// @param proposalId The ID of the proposal.
    function vote(uint256 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.voted[msg.sender], "Already voted");
        proposal.voted[msg.sender] = true;
        proposal.voteCount += balanceOf(msg.sender);
        emit Voted(proposalId, msg.sender);
    }

    /// @notice Executes a proposal if conditions are met (dummy function).
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) external onlyOwner {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Already executed");
        // In a full implementation, conditions would be checked here.
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
}
