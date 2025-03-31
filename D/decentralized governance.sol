// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DecentralizedGovernance
/// @notice Community-driven governance through proposals and voting.
contract DecentralizedGovernance is Ownable, ReentrancyGuard {

    enum ProposalStatus { Active, Passed, Failed, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 endTimestamp;
        ProposalStatus status;
        bool executed;
    }

    uint256 public proposalDuration;
    uint256 public requiredParticipation; // % (scaled by 10000, e.g., 5000 = 50%)

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public proposalCount;

    // Events
    event ProposalCreated(uint256 indexed id, address proposer, string description, uint256 endTimestamp);
    event Voted(uint256 indexed id, address voter, bool vote);
    event ProposalExecuted(uint256 indexed id);

    constructor(uint256 _proposalDuration, uint256 _requiredParticipation) Ownable(msg.sender) {
        require(_proposalDuration >= 1 days, "Minimum 1 day duration");
        require(_requiredParticipation <= 10000, "Max participation 100%");
        proposalDuration = _proposalDuration;
        requiredParticipation = _requiredParticipation;
    }

    /// @notice Create a governance proposal dynamically
    function createProposal(string calldata description) external nonReentrant {
        require(bytes(description).length > 0, "Description required");

        uint256 proposalId = proposalCount++;
        uint256 endTime = block.timestamp + proposalDuration;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            yesVotes: 0,
            noVotes: 0,
            endTimestamp: endTime,
            status: ProposalStatus.Active,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, description, endTime);
    }

    /// @notice Vote on an active proposal dynamically
    function vote(uint256 proposalId, bool support) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.endTimestamp, "Voting period ended");
        require(proposal.status == ProposalStatus.Active, "Proposal not active");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /// @notice Finalize and execute a proposal after voting ends dynamically
    function finalizeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTimestamp, "Voting ongoing");
        require(!proposal.executed, "Already executed");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes > 0, "No votes cast");

        uint256 yesPercent = (proposal.yesVotes * 10000) / totalVotes;

        if (yesPercent >= requiredParticipation) {
            proposal.status = ProposalStatus.Passed;
            _executeProposal(proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
        proposal.executed = true;
    }

    /// @notice Internal proposal execution logic
    function _executeProposal(uint256 proposalId) internal {
        // Placeholder: Implement proposal execution logic here
        // For example, changing contract parameters, transferring funds, etc.
        proposals[proposalId].status = ProposalStatus.Executed;

        emit ProposalExecuted(proposalId);
    }

    /// @notice Update proposal duration dynamically
    function setProposalDuration(uint256 newDuration) external onlyOwner {
        require(newDuration >= 1 days, "Minimum 1 day duration");
        proposalDuration = newDuration;
    }

    /// @notice Update required participation dynamically
    function setRequiredParticipation(uint256 newParticipation) external onlyOwner {
        require(newParticipation <= 10000, "Max participation 100%");
        requiredParticipation = newParticipation;
    }

    /// @notice Retrieve proposal details
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }
}
