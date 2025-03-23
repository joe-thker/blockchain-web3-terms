// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ByzantineGenerals
/// @notice This contract simulates a Byzantine Generals' Problem scenario where a group of validators
/// cast votes on a proposal and a consensus is reached when a required threshold of votes is met.
contract ByzantineGenerals {
    address public owner;
    // Percentage threshold for finalization (e.g., 67%)
    uint256 public constant THRESHOLD_PERCENT = 67;
    // List of validator addresses (the "generals")
    address[] public generals;

    // Proposal structure that holds a proposal and the votes for it.
    struct Proposal {
        uint256 id;
        string description;   // Proposal text (e.g., "attack" or "retreat")
        uint256 trueVotes;    // Votes for "attack"
        uint256 falseVotes;   // Votes for "retreat"
        uint256 totalVotes;   // Total votes cast
        bool finalized;       // Whether the proposal has been finalized
        bool decision;        // True if accepted ("attack"), false if rejected ("retreat")
        mapping(address => bool) voted; // Tracks which generals have voted
    }

    // Mapping of proposal ID to Proposal
    mapping(uint256 => Proposal) private proposals;
    uint256 public proposalCount;

    event ProposalSubmitted(uint256 indexed proposalId, string description);
    event VoteCast(uint256 indexed proposalId, address indexed general, bool vote);
    event ProposalFinalized(uint256 indexed proposalId, bool decision);

    modifier onlyGeneral() {
        bool isGeneral = false;
        for (uint256 i = 0; i < generals.length; i++) {
            if (generals[i] == msg.sender) {
                isGeneral = true;
                break;
            }
        }
        require(isGeneral, "Caller is not a general");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the owner and the list of generals.
    /// @param _generals Array of validator addresses representing the generals.
    constructor(address[] memory _generals) {
        owner = msg.sender;
        generals = _generals;
    }

    /// @notice Allows a general to submit a new proposal.
    /// @param _description A description of the proposal.
    /// @return proposalId The unique ID of the submitted proposal.
    function submitProposal(string calldata _description) external onlyGeneral returns (uint256 proposalId) {
        proposalId = proposalCount;
        Proposal storage p = proposals[proposalId];
        p.id = proposalId;
        p.description = _description;
        p.trueVotes = 0;
        p.falseVotes = 0;
        p.totalVotes = 0;
        p.finalized = false;
        proposalCount++;
        emit ProposalSubmitted(proposalId, _description);
    }

    /// @notice Allows a general to vote on an existing proposal.
    /// @param proposalId The ID of the proposal.
    /// @param voteValue True for "attack", false for "retreat".
    function vote(uint256 proposalId, bool voteValue) external onlyGeneral {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage p = proposals[proposalId];
        require(!p.finalized, "Proposal already finalized");
        require(!p.voted[msg.sender], "General already voted");

        p.voted[msg.sender] = true;
        p.totalVotes++;
        if (voteValue) {
            p.trueVotes++;
        } else {
            p.falseVotes++;
        }
        emit VoteCast(proposalId, msg.sender, voteValue);

        if (p.totalVotes >= requiredVotes()) {
            p.finalized = true;
            // Final decision is based on majority vote.
            p.decision = p.trueVotes > p.falseVotes;
            emit ProposalFinalized(proposalId, p.decision);
        }
    }

    /// @notice Calculates the minimum number of votes required to finalize a proposal.
    /// @return The required number of votes.
    function requiredVotes() public view returns (uint256) {
        // Ceiling of (number of generals * THRESHOLD_PERCENT / 100)
        return (generals.length * THRESHOLD_PERCENT + 99) / 100;
    }

    /// @notice Retrieves details of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return id The proposal ID.
    /// @return description The proposal description.
    /// @return trueVotes Number of votes for "attack".
    /// @return falseVotes Number of votes for "retreat".
    /// @return totalVotes Total votes cast.
    /// @return finalized Whether the proposal is finalized.
    /// @return decision The final decision (true if "attack" was chosen, false if "retreat").
    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        string memory description,
        uint256 trueVotes,
        uint256 falseVotes,
        uint256 totalVotes,
        bool finalized,
        bool decision
    ) {
        require(proposalId < proposalCount, "Proposal does not exist");
        Proposal storage p = proposals[proposalId];
        return (p.id, p.description, p.trueVotes, p.falseVotes, p.totalVotes, p.finalized, p.decision);
    }
}
