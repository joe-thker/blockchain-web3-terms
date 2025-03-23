// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ByzantineFaultTolerance {
    address public owner;
    // Percentage threshold (e.g., 67% required to finalize a proposal)
    uint256 public constant THRESHOLD_PERCENT = 67;
    // Array of validator addresses.
    address[] public validators;

    // Structure for a proposal.
    struct Proposal {
        uint256 id;
        string description;
        uint256 trueVotes;
        uint256 falseVotes;
        uint256 totalVotes;
        bool finalized;
        bool decision; // true if accepted, false if rejected
        mapping(address => bool) voted;
    }

    // Mapping from proposal ID to Proposal.
    mapping(uint256 => Proposal) private proposals;
    uint256 public proposalCount;

    event ProposalSubmitted(uint256 indexed proposalId, string description);
    event Voted(uint256 indexed proposalId, address indexed validator, bool vote);
    event ProposalFinalized(uint256 indexed proposalId, bool decision);

    modifier onlyValidator() {
        bool isValidator = false;
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == msg.sender) {
                isValidator = true;
                break;
            }
        }
        require(isValidator, "Not a validator");
        _;
    }

    constructor(address[] memory _validators) {
        owner = msg.sender;
        validators = _validators;
    }

    /// @notice Submits a new proposal. Only validators can submit proposals.
    /// @param description A description of the proposal.
    /// @return proposalId The unique ID of the submitted proposal.
    function submitProposal(string calldata description) external onlyValidator returns (uint256 proposalId) {
        proposalId = proposalCount;
        Proposal storage p = proposals[proposalId];
        p.id = proposalId;
        p.description = description;
        p.trueVotes = 0;
        p.falseVotes = 0;
        p.totalVotes = 0;
        p.finalized = false;
        p.decision = false;
        proposalCount++;
        emit ProposalSubmitted(proposalId, description);
    }

    /// @notice Casts a vote on a proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param voteValue The vote (true for acceptance, false for rejection).
    function vote(uint256 proposalId, bool voteValue) external onlyValidator {
        Proposal storage p = proposals[proposalId];
        require(!p.finalized, "Proposal already finalized");
        require(!p.voted[msg.sender], "Validator already voted");

        p.voted[msg.sender] = true;
        p.totalVotes++;
        if (voteValue) {
            p.trueVotes++;
        } else {
            p.falseVotes++;
        }
        emit Voted(proposalId, msg.sender, voteValue);

        // If the number of votes reaches the required threshold, finalize the proposal.
        if (p.totalVotes >= requiredVotes()) {
            p.finalized = true;
            p.decision = (p.trueVotes > p.falseVotes);
            emit ProposalFinalized(proposalId, p.decision);
        }
    }

    /// @notice Calculates the minimum number of votes required for finalization.
    /// @return The required number of votes.
    function requiredVotes() public view returns (uint256) {
        // Round up: requiredVotes = ceil(validators.length * THRESHOLD_PERCENT / 100)
        return (validators.length * THRESHOLD_PERCENT + 99) / 100;
    }

    /// @notice Retrieves proposal details by its ID.
    /// @param proposalId The ID of the proposal.
    /// @return id The proposal ID.
    /// @return description The proposal description.
    /// @return trueVotes Number of "true" votes.
    /// @return falseVotes Number of "false" votes.
    /// @return totalVotes Total votes cast.
    /// @return finalized Whether the proposal is finalized.
    /// @return decision The final decision (true if accepted, false if rejected).
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
        id = p.id;
        description = p.description;
        trueVotes = p.trueVotes;
        falseVotes = p.falseVotes;
        totalVotes = p.totalVotes;
        finalized = p.finalized;
        decision = p.decision;
    }
}
