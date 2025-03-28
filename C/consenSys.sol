// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ConsensusSystem
/// @notice This contract implements a dynamic and secure consensus mechanism.
/// Validators can propose actions and vote on them. When a proposal reaches the required vote threshold,
/// it can be executed. The system is dynamic (validators and vote threshold are updateable),
/// optimized in storage, and secured using Ownable and ReentrancyGuard.
contract ConsensusSystem is Ownable, ReentrancyGuard {
    // Array of validator addresses.
    address[] public validators;
    // Quick lookup for validator status.
    mapping(address => bool) public isValidator;
    // Number of votes required for a proposal to be executed.
    uint256 public requiredVotes;

    // Proposal structure.
    struct Proposal {
        uint256 id;            // Unique proposal ID.
        address proposer;      // Address of the proposer.
        string description;    // Proposal description.
        bytes data;            // Arbitrary data (could be used for off-chain or on-chain execution).
        uint256 voteCount;     // Number of votes received.
        bool executed;         // Whether the proposal has been executed.
        // Mapping to track which validator has already voted.
        mapping(address => bool) hasVoted;
    }

    // Mapping from proposal ID to Proposal details.
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
        require(isValidator[msg.sender], "Caller is not a validator");
        _;
    }

    /// @notice Constructor sets the initial validators and required vote threshold.
    /// @param _validators Array of initial validator addresses.
    /// @param _requiredVotes Number of votes required for consensus.
    constructor(address[] memory _validators, uint256 _requiredVotes) Ownable(msg.sender) {
        require(_validators.length > 0, "At least one validator required");
        require(_requiredVotes > 0 && _requiredVotes <= _validators.length, "Invalid threshold");

        for (uint256 i = 0; i < _validators.length; i++) {
            address v = _validators[i];
            require(v != address(0), "Validator address cannot be zero");
            require(!isValidator[v], "Duplicate validator");
            isValidator[v] = true;
            validators.push(v);
            emit ValidatorAdded(v);
        }
        requiredVotes = _requiredVotes;
        emit RequiredVotesUpdated(requiredVotes);
    }

    /// @notice Allows a validator to create a new proposal.
    /// @param _description A brief description of the proposal.
    /// @param _data Arbitrary data associated with the proposal.
    /// @return proposalId The unique ID of the created proposal.
    function createProposal(string calldata _description, bytes calldata _data)
        external
        onlyValidator
        returns (uint256 proposalId)
    {
        proposalCount++;
        proposalId = proposalCount;

        // Initialize proposal in storage.
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.data = _data;
        newProposal.voteCount = 0;
        newProposal.executed = false;

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /// @notice Allows a validator to vote on an existing proposal.
    /// @param proposalId The ID of the proposal to vote on.
    function vote(uint256 proposalId) external onlyValidator nonReentrant {
        Proposal storage prop = proposals[proposalId];
        require(prop.id != 0, "Proposal does not exist");
        require(!prop.executed, "Proposal already executed");
        require(!prop.hasVoted[msg.sender], "Validator has already voted");

        prop.hasVoted[msg.sender] = true;
        prop.voteCount += 1;
        emit VoteCast(proposalId, msg.sender, prop.voteCount);
    }

    /// @notice Executes a proposal if it has reached the required vote threshold.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external onlyValidator nonReentrant {
        Proposal storage prop = proposals[proposalId];
        require(prop.id != 0, "Proposal does not exist");
        require(!prop.executed, "Proposal already executed");
        require(prop.voteCount >= requiredVotes, "Insufficient votes");

        prop.executed = true;
        // Optionally: add logic to process prop.data or trigger an action.
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

    /// @notice Allows the owner to add a new validator.
    /// @param newValidator The address of the validator to add.
    function addValidator(address newValidator) external onlyOwner {
        require(newValidator != address(0), "Invalid validator address");
        require(!isValidator[newValidator], "Address is already a validator");
        isValidator[newValidator] = true;
        validators.push(newValidator);
        emit ValidatorAdded(newValidator);
    }

    /// @notice Allows the owner to remove an existing validator.
    /// @param validatorToRemove The address of the validator to remove.
    function removeValidator(address validatorToRemove) external onlyOwner {
        require(isValidator[validatorToRemove], "Address is not a validator");
        isValidator[validatorToRemove] = false;

        // Remove from the validators array.
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == validatorToRemove) {
                validators[i] = validators[validators.length - 1];
                validators.pop();
                break;
            }
        }
        emit ValidatorRemoved(validatorToRemove);

        // Adjust requiredVotes if needed.
        if (requiredVotes > validators.length) {
            requiredVotes = validators.length;
            emit RequiredVotesUpdated(requiredVotes);
        }
    }

    /// @notice Allows the owner to update the required vote threshold.
    /// @param newRequiredVotes New number of votes required.
    function updateRequiredVotes(uint256 newRequiredVotes) external onlyOwner {
        require(newRequiredVotes > 0 && newRequiredVotes <= validators.length, "Invalid threshold");
        requiredVotes = newRequiredVotes;
        emit RequiredVotesUpdated(newRequiredVotes);
    }
}
