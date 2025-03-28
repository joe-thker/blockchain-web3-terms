// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ConsensusMechanism
/// @notice This contract allows a dynamic set of validators to propose actions and vote on them.
/// When a proposal receives the required number of votes, it is marked as executed.
/// The contract is dynamic (validators and vote threshold can be updated), optimized in storage,
/// and uses security measures such as reentrancy protection and access control.
contract ConsensusMechanism is Ownable, ReentrancyGuard {
    // Dynamic list of validator addresses.
    address[] public validators;
    mapping(address => bool) public isValidator;

    // Required number of votes for consensus.
    uint256 public requiredVotes;

    // Proposal structure.
    struct Proposal {
        uint256 id;             // Unique proposal ID.
        address proposer;       // Address of the proposer.
        string description;     // Proposal description.
        bytes data;             // Arbitrary data associated with the proposal.
        uint256 voteCount;      // Number of votes received.
        bool executed;          // Whether the proposal has been executed.
        // Mapping to track which validator has voted.
        mapping(address => bool) hasVoted;
    }

    // Mapping of proposal ID to Proposal details.
    mapping(uint256 => Proposal) private proposals;
    uint256 public proposalCount;

    // --- Events ---
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed validator, uint256 voteCount);
    event ProposalExecuted(uint256 indexed proposalId);
    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);
    event RequiredVotesUpdated(uint256 newRequiredVotes);

    // --- Modifiers ---
    modifier onlyValidator() {
        require(isValidator[msg.sender], "Not a validator");
        _;
    }

    /// @notice Constructor sets the initial validators and required votes for consensus.
    /// @param _validators Array of initial validator addresses.
    /// @param _requiredVotes Number of votes required to execute a proposal.
    constructor(address[] memory _validators, uint256 _requiredVotes) Ownable(msg.sender) {
        require(_validators.length > 0, "At least one validator required");
        require(_requiredVotes > 0 && _requiredVotes <= _validators.length, "Invalid required votes");

        for (uint256 i = 0; i < _validators.length; i++) {
            address v = _validators[i];
            require(v != address(0), "Invalid validator address");
            require(!isValidator[v], "Duplicate validator");
            isValidator[v] = true;
            validators.push(v);
            emit ValidatorAdded(v);
        }
        requiredVotes = _requiredVotes;
        emit RequiredVotesUpdated(_requiredVotes);
    }

    /// @notice Creates a new proposal.
    /// @param _description A short description of the proposal.
    /// @param _data Arbitrary data associated with the proposal.
    /// @return proposalId The unique ID assigned to the new proposal.
    function createProposal(string calldata _description, bytes calldata _data)
        external
        onlyValidator
        returns (uint256 proposalId)
    {
        proposalCount++;
        proposalId = proposalCount;

        // Initialize proposal in storage. Note that mappings inside structs are automatically empty.
        Proposal storage prop = proposals[proposalId];
        prop.id = proposalId;
        prop.proposer = msg.sender;
        prop.description = _description;
        prop.data = _data;
        prop.voteCount = 0;
        prop.executed = false;

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /// @notice Allows a validator to vote on a proposal.
    /// @param proposalId The ID of the proposal to vote on.
    function vote(uint256 proposalId) external onlyValidator nonReentrant {
        Proposal storage prop = proposals[proposalId];
        require(prop.id != 0, "Proposal does not exist");
        require(!prop.executed, "Proposal already executed");
        require(!prop.hasVoted[msg.sender], "Validator already voted");

        prop.hasVoted[msg.sender] = true;
        prop.voteCount++;
        emit VoteCast(proposalId, msg.sender, prop.voteCount);
    }

    /// @notice Executes a proposal if it has reached the required number of votes.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external onlyValidator nonReentrant {
        Proposal storage prop = proposals[proposalId];
        require(prop.id != 0, "Proposal does not exist");
        require(!prop.executed, "Proposal already executed");
        require(prop.voteCount >= requiredVotes, "Not enough votes");

        prop.executed = true;
        // (Optionally, add logic here to process prop.data if needed.)
        emit ProposalExecuted(proposalId);
    }

    /// @notice Retrieves details of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return id Proposal ID.
    /// @return proposer Address of the proposer.
    /// @return description Proposal description.
    /// @return data Arbitrary proposal data.
    /// @return voteCount Number of votes received.
    /// @return executed Whether the proposal has been executed.
    function getProposal(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            bytes memory data,
            uint256 voteCount,
            bool executed
        )
    {
        Proposal storage prop = proposals[proposalId];
        require(prop.id != 0, "Proposal does not exist");
        return (prop.id, prop.proposer, prop.description, prop.data, prop.voteCount, prop.executed);
    }

    /// @notice Adds a new validator. Only the owner can call this.
    /// @param newValidator The address of the validator to add.
    function addValidator(address newValidator) external onlyOwner {
        require(newValidator != address(0), "Invalid address");
        require(!isValidator[newValidator], "Already a validator");
        isValidator[newValidator] = true;
        validators.push(newValidator);
        emit ValidatorAdded(newValidator);
    }

    /// @notice Removes a validator. Only the owner can call this.
    /// @param validatorToRemove The address of the validator to remove.
    function removeValidator(address validatorToRemove) external onlyOwner {
        require(isValidator[validatorToRemove], "Not a validator");
        isValidator[validatorToRemove] = false;
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == validatorToRemove) {
                validators[i] = validators[validators.length - 1];
                validators.pop();
                break;
            }
        }
        emit ValidatorRemoved(validatorToRemove);
        // If the requiredVotes threshold is now higher than the number of validators, adjust it.
        if (requiredVotes > validators.length) {
            requiredVotes = validators.length;
            emit RequiredVotesUpdated(requiredVotes);
        }
    }

    /// @notice Updates the required number of votes for consensus. Only the owner can call this.
    /// @param newRequiredVotes New threshold value.
    function updateRequiredVotes(uint256 newRequiredVotes) external onlyOwner {
        require(newRequiredVotes > 0 && newRequiredVotes <= validators.length, "Invalid threshold");
        requiredVotes = newRequiredVotes;
        emit RequiredVotesUpdated(newRequiredVotes);
    }
}
