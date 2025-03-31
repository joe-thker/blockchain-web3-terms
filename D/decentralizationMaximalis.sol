// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DecentralizationMaximalist
/// @notice A contract to propose, vote, and track decentralization-focused proposals.
contract DecentralizationMaximalist is Ownable, ReentrancyGuard {

    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteCount;
        bool active;
        uint256 timestamp;
    }

    // Mapping of proposal ID to Proposal
    mapping(uint256 => Proposal) public proposals;

    // Proposal voting status: proposalId => voter address => bool
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Incremental ID for proposals
    uint256 public nextProposalId;

    // Active proposal IDs for enumeration
    uint256[] public activeProposalIds;

    // Events
    event ProposalSubmitted(uint256 indexed proposalId, address proposer, string description);
    event Voted(uint256 indexed proposalId, address voter);
    event ProposalClosed(uint256 indexed proposalId);

    constructor() Ownable(msg.sender) {}

    /// @notice Submit a new decentralization proposal dynamically
    function submitProposal(string calldata description) external nonReentrant {
        require(bytes(description).length > 0, "Description required");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            voteCount: 0,
            active: true,
            timestamp: block.timestamp
        });

        activeProposalIds.push(proposalId);
        emit ProposalSubmitted(proposalId, msg.sender, description);
    }

    /// @notice Vote on an active proposal
    function vote(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.active, "Proposal inactive or nonexistent");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;
        proposal.voteCount++;

        emit Voted(proposalId, msg.sender);
    }

    /// @notice Owner can close a proposal
    function closeProposal(uint256 proposalId) external onlyOwner nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.active, "Already inactive");

        proposal.active = false;

        // Remove from activeProposalIds array efficiently
        for (uint256 i = 0; i < activeProposalIds.length; i++) {
            if (activeProposalIds[i] == proposalId) {
                activeProposalIds[i] = activeProposalIds[activeProposalIds.length - 1];
                activeProposalIds.pop();
                break;
            }
        }

        emit ProposalClosed(proposalId);
    }

    /// @notice Retrieve proposal details
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }

    /// @notice List all active proposal IDs
    function getActiveProposals() external view returns (uint256[] memory) {
        return activeProposalIds;
    }

    /// @notice Check if an address voted on a proposal
    function checkVoteStatus(uint256 proposalId, address voter) external view returns (bool) {
        return hasVoted[proposalId][voter];
    }
}
