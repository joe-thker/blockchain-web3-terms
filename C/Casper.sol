// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SimpleCasper
/// @notice A simplified simulation of a Casper-like Proof-of-Stake protocol.
/// Validators can deposit stake, submit proposals, and vote on proposals.
/// When a proposal receives enough votes, it is finalized.
contract SimpleCasper {
    address public owner;
    uint256 public validatorCount;
    uint256 public totalStake;
    // finalityThreshold in basis points (e.g., 6670 means 66.7% of validators must vote to finalize a proposal)
    uint256 public finalityThreshold; 

    struct Validator {
        bool exists;
        uint256 stake;
    }
    mapping(address => Validator) public validators;
    address[] public validatorAddresses;

    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCount;
        bool finalized;
        bool decision; // true if accepted (e.g., block is valid), false otherwise
        mapping(address => bool) voted; // tracks which validator has voted
    }
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    event ValidatorDeposited(address indexed validator, uint256 stake);
    event ProposalSubmitted(uint256 indexed proposalId, string description);
    event VoteCast(uint256 indexed proposalId, address indexed validator);
    event ProposalFinalized(uint256 indexed proposalId, bool decision);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyValidator() {
        require(validators[msg.sender].exists, "Caller is not a validator");
        _;
    }

    constructor(uint256 _finalityThreshold) {
        owner = msg.sender;
        finalityThreshold = _finalityThreshold; // e.g., 6670 for 66.7%
    }

    /// @notice Allows a user to deposit stake and become a validator.
    function depositStake() external payable {
        require(msg.value > 0, "Stake must be > 0");
        require(!validators[msg.sender].exists, "Already a validator");

        validators[msg.sender] = Validator({ exists: true, stake: msg.value });
        validatorAddresses.push(msg.sender);
        validatorCount++;
        totalStake += msg.value;

        emit ValidatorDeposited(msg.sender, msg.value);
    }

    /// @notice Allows a validator to submit a proposal (e.g., a block candidate).
    /// @param description A description of the proposal.
    function submitProposal(string calldata description) external onlyValidator {
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.description = description;
        p.voteCount = 0;
        p.finalized = false;
        emit ProposalSubmitted(proposalCount, description);
        proposalCount++;
    }

    /// @notice Allows a validator to vote on a proposal.
    /// @param proposalId The proposal ID.
    /// @param voteValue The vote value (true for "accept", false for "reject").
    function voteOnProposal(uint256 proposalId, bool voteValue) external onlyValidator {
        require(proposalId < proposalCount, "Invalid proposalId");
        Proposal storage p = proposals[proposalId];
        require(!p.finalized, "Proposal already finalized");
        require(!p.voted[msg.sender], "Already voted");

        p.voted[msg.sender] = true;
        p.voteCount++;
        emit VoteCast(proposalId, msg.sender);

        if (hasFinality(p.voteCount)) {
            p.finalized = true;
            // For simplicity, decision is based on majority "accept" votes.
            // In this simplified version, we treat any finalized proposal as accepted.
            p.decision = true;
            emit ProposalFinalized(proposalId, p.decision);
        }
    }

    /// @notice Checks if the proposal has reached the required number of votes to finalize.
    /// @param voteCount The current vote count.
    /// @return True if finalized, false otherwise.
    function hasFinality(uint256 voteCount) internal view returns (bool) {
        // Calculate required votes: ceiling(validators * finalityThreshold / 10000)
        uint256 requiredVotes = (validatorCount * finalityThreshold + 9999) / 10000;
        if (requiredVotes == 0) {
            requiredVotes = 1;
        }
        return voteCount >= requiredVotes;
    }

    // @notice Retrieves details of a proposal.
    // @param proposalId The proposal ID.
    // @return description, voteCount, finalized status, and decision.
    function getProposal(uint256 proposalId) external view returns (
        string memory description,
        uint256 voteCount,
        bool finalized,
        bool decision
    ) {
        require(proposalId < proposalCount, "Invalid proposalId");
        Proposal storage p = proposals[proposalId];
        return (p.description, p.voteCount, p.finalized, p.decision);
    }

    /// @notice Returns the total number of validators.
    function getValidatorCount() external view returns (uint256) {
        return validatorCount;
    }
}
