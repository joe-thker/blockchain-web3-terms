// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ConsensusLayer
/// @notice This contract implements a consensus mechanism where a set of validators 
/// dynamically submit votes on a proposal. Votes are collected on a per‑round basis, 
/// and once the vote count for a proposal reaches the required threshold, that proposal 
/// is accepted as the consensus value and the round is advanced.
contract ConsensusLayer is Ownable, ReentrancyGuard {
    // Dynamic set of validator addresses.
    address[] public validators;
    mapping(address => bool) public isValidator;
    // The number of votes required to reach consensus.
    uint256 public requiredValidators;

    // Round-based voting mechanism.
    uint256 public currentRound;

    // Each validator's vote for the current round.
    struct Vote {
        uint256 round;      // The round in which the vote was cast.
        bytes32 proposal;   // The proposal (as a bytes32 value).
    }
    mapping(address => Vote) public validatorVotes;
    // Mapping: round number => (proposal => vote count)
    mapping(uint256 => mapping(bytes32 => uint256)) public roundProposalVotes;

    // The most recent consensus value and the timestamp of its update.
    bytes32 public consensusValue;
    uint256 public lastUpdate;

    // --- Events ---
    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);
    event RequiredValidatorsUpdated(uint256 newRequiredValidators);
    event VoteSubmitted(address indexed validator, uint256 round, bytes32 proposal, uint256 voteCount);
    event ConsensusUpdated(uint256 round, bytes32 consensusValue, uint256 timestamp);

    // --- Modifiers ---
    modifier onlyValidator() {
        require(isValidator[msg.sender], "Not a validator");
        _;
    }

    /// @notice Constructor sets the initial validators and required vote threshold.
    /// @param initialValidators Array of initial validator addresses.
    /// @param _requiredValidators The number of votes required for consensus.
    constructor(address[] memory initialValidators, uint256 _requiredValidators) Ownable(msg.sender) {
        require(initialValidators.length > 0, "At least one validator required");
        require(
            _requiredValidators > 0 && _requiredValidators <= initialValidators.length,
            "Invalid required validators"
        );
        for (uint256 i = 0; i < initialValidators.length; i++) {
            address v = initialValidators[i];
            require(v != address(0), "Invalid validator address");
            require(!isValidator[v], "Duplicate validator");
            isValidator[v] = true;
            validators.push(v);
            emit ValidatorAdded(v);
        }
        requiredValidators = _requiredValidators;
        emit RequiredValidatorsUpdated(_requiredValidators);
        currentRound = 1;
    }

    /// @notice Allows the owner to add a new validator.
    /// @param validator The address of the new validator.
    function addValidator(address validator) external onlyOwner {
        require(validator != address(0), "Invalid validator");
        require(!isValidator[validator], "Already a validator");
        isValidator[validator] = true;
        validators.push(validator);
        emit ValidatorAdded(validator);
    }

    /// @notice Allows the owner to remove an existing validator.
    /// @param validator The address of the validator to remove.
    function removeValidator(address validator) external onlyOwner {
        require(isValidator[validator], "Not a validator");
        isValidator[validator] = false;
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == validator) {
                validators[i] = validators[validators.length - 1];
                validators.pop();
                break;
            }
        }
        if (requiredValidators > validators.length) {
            requiredValidators = validators.length;
            emit RequiredValidatorsUpdated(requiredValidators);
        }
        emit ValidatorRemoved(validator);
    }

    /// @notice Allows the owner to update the required number of validators for consensus.
    /// @param _requiredValidators New threshold (must be > 0 and ≤ number of validators).
    function updateRequiredValidators(uint256 _requiredValidators) external onlyOwner {
        require(_requiredValidators > 0 && _requiredValidators <= validators.length, "Invalid threshold");
        requiredValidators = _requiredValidators;
        emit RequiredValidatorsUpdated(_requiredValidators);
    }

    /// @notice Allows a validator to submit a vote for a proposal in the current round.
    /// @param proposal The proposal value as a bytes32.
    function submitVote(bytes32 proposal) external onlyValidator nonReentrant {
        require(proposal != bytes32(0), "Invalid proposal");
        Vote storage voteRecord = validatorVotes[msg.sender];

        // If validator hasn't voted in the current round, treat this as a new vote.
        if (voteRecord.round != currentRound) {
            voteRecord.round = currentRound;
            voteRecord.proposal = proposal;
            roundProposalVotes[currentRound][proposal] += 1;
            emit VoteSubmitted(msg.sender, currentRound, proposal, roundProposalVotes[currentRound][proposal]);
        } else {
            // If already voted in this round with a different proposal, update the vote.
            if (voteRecord.proposal != proposal) {
                // Decrement count for previous proposal.
                roundProposalVotes[currentRound][voteRecord.proposal] -= 1;
                // Update vote.
                voteRecord.proposal = proposal;
                roundProposalVotes[currentRound][proposal] += 1;
                emit VoteSubmitted(msg.sender, currentRound, proposal, roundProposalVotes[currentRound][proposal]);
            } else {
                revert("Already voted for this proposal");
            }
        }

        // Check if consensus is reached.
        if (roundProposalVotes[currentRound][proposal] >= requiredValidators) {
            consensusValue = proposal;
            lastUpdate = block.timestamp;
            emit ConsensusUpdated(currentRound, consensusValue, lastUpdate);
            // Start a new round.
            currentRound += 1;
        }
    }

    /// @notice Returns the vote count for a given proposal in the current round.
    /// @param proposal The proposal value.
    function getVoteCount(bytes32 proposal) external view returns (uint256) {
        return roundProposalVotes[currentRound][proposal];
    }
}
