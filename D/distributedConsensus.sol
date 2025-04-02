// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DistributedConsensus
/// @notice A dynamic and optimized contract simulating a simplified multi-participant consensus mechanism.
/// The owner manages a set of participants. Participants can create proposals and vote on them.
/// A proposal is accepted once it meets a specified vote threshold, representing a “consensus.”
contract DistributedConsensus is Ownable, ReentrancyGuard {
    /// @notice A structure representing a proposal within the system.
    struct Proposal {
        uint256 id;              // Proposal ID
        address proposer;        // The participant who created the proposal
        string description;      // Text or reference describing the proposal
        uint256 voteCount;       // Number of participants who voted "yes" on this proposal
        bool accepted;           // True if consensus threshold has been reached
        bool active;             // True if proposal is still active (not canceled or concluded)
        uint256 createdAt;       // Timestamp when proposal was created
    }

    // Auto-incremented proposal ID counter
    uint256 public nextProposalId;

    /// @notice Array storing all proposals (including concluded). Index is proposalId.
    Proposal[] public proposals;

    /// @notice Mapping from proposalId => address => whether that address has voted
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    /// @notice Mapping of participant address => bool indicating if they are a recognized participant.
    mapping(address => bool) public isParticipant;

    // --- Admin-Configurable Fields ---
    /// @notice The vote threshold for acceptance in basis points (e.g. 5000 = 50%). 
    /// Once (voteCount / totalParticipants) * 10000 >= acceptanceThresholdBps, proposal is accepted.
    uint256 public acceptanceThresholdBps;

    /// @notice Tracks the total number of recognized participants
    uint256 public totalParticipants;

    // --- Events ---
    event ParticipantAdded(address indexed participant);
    event ParticipantRemoved(address indexed participant);
    event AcceptanceThresholdUpdated(uint256 newThresholdBps);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, uint256 voteCount);
    event ProposalAccepted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    /// @notice Constructor sets the deployer as the initial owner, and sets an initial acceptance threshold.
    /// @param initialThresholdBps The acceptance threshold in basis points (1–10000).
    constructor(uint256 initialThresholdBps) Ownable(msg.sender) {
        require(initialThresholdBps <= 10000, "Threshold must be <= 100%");
        acceptanceThresholdBps = initialThresholdBps;
    }

    // --- Owner Functions ---

    /// @notice Adds a new participant who can create and vote on proposals.
    /// @param participant The address of the participant to add.
    function addParticipant(address participant) external onlyOwner {
        require(participant != address(0), "Invalid participant address");
        require(!isParticipant[participant], "Already a participant");

        isParticipant[participant] = true;
        totalParticipants++;
        emit ParticipantAdded(participant);
    }

    /// @notice Removes an existing participant from voting/creating proposals.
    /// @param participant The address of the participant to remove.
    function removeParticipant(address participant) external onlyOwner {
        require(isParticipant[participant], "Not a participant");
        isParticipant[participant] = false;
        totalParticipants--;
        emit ParticipantRemoved(participant);
    }

    /// @notice Updates the acceptance threshold. (e.g. 6000 = 60%)
    /// @param newThresholdBps The new acceptance threshold in basis points.
    function updateAcceptanceThreshold(uint256 newThresholdBps) external onlyOwner {
        require(newThresholdBps <= 10000, "Threshold must be <= 100%");
        acceptanceThresholdBps = newThresholdBps;
        emit AcceptanceThresholdUpdated(newThresholdBps);
    }

    // --- Participant Functions ---

    /// @notice Creates a new proposal. Only recognized participants can create proposals.
    /// @param description A text or reference describing the proposal.
    /// @return proposalId The unique ID assigned to the new proposal.
    function createProposal(string calldata description)
        external
        nonReentrant
        returns (uint256 proposalId)
    {
        require(isParticipant[msg.sender], "Only participants can create proposals");
        require(bytes(description).length > 0, "Description cannot be empty");

        proposalId = nextProposalId++;
        proposals.push(Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            voteCount: 0,
            accepted: false,
            active: true,
            createdAt: block.timestamp
        }));

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /// @notice A participant votes "yes" on an active proposal. If threshold is met, the proposal is accepted.
    /// @param proposalId The ID of the proposal to vote on.
    function voteOnProposal(uint256 proposalId) external nonReentrant {
        require(isParticipant[msg.sender], "Only participants can vote");
        require(proposalId < proposals.length, "Invalid proposal ID");

        Proposal storage prop = proposals[proposalId];
        require(prop.active, "Proposal not active");
        require(!prop.accepted, "Proposal already accepted");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;
        prop.voteCount++;

        emit ProposalVoted(proposalId, msg.sender, prop.voteCount);

        // Check if threshold is met
        // If (prop.voteCount / totalParticipants) * 10000 >= acceptanceThresholdBps => accepted
        if (!_checkAccepted(prop.voteCount)) {
            return;
        }
        prop.accepted = true;
        emit ProposalAccepted(proposalId);
    }

    /// @notice The proposal creator can cancel the proposal if it is still active and not accepted.
    /// @param proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 proposalId) external nonReentrant {
        require(proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage prop = proposals[proposalId];
        require(prop.active, "Proposal not active");
        require(!prop.accepted, "Proposal already accepted");
        require(prop.proposer == msg.sender, "Not proposal creator");

        prop.active = false;
        emit ProposalCanceled(proposalId);
    }

    // --- View Functions ---

    /// @notice Returns the total number of proposals ever created (including canceled/accepted).
    /// @return The length of the proposals array.
    function totalProposals() external view returns (uint256) {
        return proposals.length;
    }

    /// @notice Retrieves a proposal by ID.
    /// @param proposalId The ID of the proposal to get.
    /// @return The proposal struct with details.
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        require(proposalId < proposals.length, "Invalid proposal ID");
        return proposals[proposalId];
    }

    // --- Internal Helpers ---

    /// @notice Checks if the given voteCount meets or exceeds the acceptance threshold ratio.
    /// e.g. if acceptanceThresholdBps=6000 => 60%, 
    /// voteCount / totalParticipants >= 60% => accepted.
    /// @return True if threshold is met, false otherwise.
    function _checkAccepted(uint256 voteCount) internal view returns (bool) {
        if (totalParticipants == 0) return false;
        // (voteCount * 10000) / totalParticipants >= acceptanceThresholdBps
        uint256 ratioBps = (voteCount * 10000) / totalParticipants;
        return ratioBps >= acceptanceThresholdBps;
    }
}
