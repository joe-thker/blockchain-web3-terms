// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Consensus
/// @notice This contract allows a dynamic set of validators to submit proposals and vote on them.
/// When a proposal receives at least the required number of votes, consensus is reached.
contract Consensus is Ownable, ReentrancyGuard {
    // Array of validator addresses.
    address[] public validators;
    // Mapping for quick validator lookup.
    mapping(address => bool) public isValidator;
    
    // Number of votes required to reach consensus.
    uint256 public requiredVotes;
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes data;
        uint256 voteCount;
        bool consensusReached;
        // Mapping to track whether a validator has already voted.
        mapping(address => bool) votes;
    }
    
    // Mapping from proposal ID to Proposal details.
    mapping(uint256 => Proposal) private proposals;
    uint256 public nextProposalId;
    
    // --- Events ---
    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);
    event RequiredVotesUpdated(uint256 newRequiredVotes);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed validator, uint256 voteCount);
    event ConsensusReached(uint256 indexed proposalId);
    
    // --- Modifiers ---
    modifier onlyValidator() {
        require(isValidator[msg.sender], "Not a validator");
        _;
    }
    
    /// @notice Constructor sets the initial validators and the required number of votes for consensus.
    /// @param _validators Array of initial validator addresses.
    /// @param _requiredVotes The number of votes required for consensus.
    constructor(address[] memory _validators, uint256 _requiredVotes) Ownable(msg.sender) {
        require(_validators.length > 0, "At least one validator required");
        require(_requiredVotes > 0 && _requiredVotes <= _validators.length, "Invalid required votes");
        
        for (uint256 i = 0; i < _validators.length; i++) {
            address validator = _validators[i];
            require(validator != address(0), "Invalid validator address");
            require(!isValidator[validator], "Duplicate validator");
            
            isValidator[validator] = true;
            validators.push(validator);
            emit ValidatorAdded(validator);
        }
        
        requiredVotes = _requiredVotes;
        emit RequiredVotesUpdated(_requiredVotes);
    }
    
    /// @notice Allows the owner to add a new validator.
    /// @param _validator Address of the validator to add.
    function addValidator(address _validator) external onlyOwner {
        require(_validator != address(0), "Invalid validator address");
        require(!isValidator[_validator], "Validator already exists");
        
        isValidator[_validator] = true;
        validators.push(_validator);
        emit ValidatorAdded(_validator);
    }
    
    /// @notice Allows the owner to remove an existing validator.
    /// @param _validator Address of the validator to remove.
    function removeValidator(address _validator) external onlyOwner {
        require(isValidator[_validator], "Not a validator");
        isValidator[_validator] = false;
        
        // Remove from the validators array.
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == _validator) {
                validators[i] = validators[validators.length - 1];
                validators.pop();
                break;
            }
        }
        emit ValidatorRemoved(_validator);
        
        // Adjust requiredVotes if necessary.
        if (requiredVotes > validators.length) {
            requiredVotes = validators.length;
            emit RequiredVotesUpdated(requiredVotes);
        }
    }
    
    /// @notice Allows the owner to update the consensus threshold.
    /// @param _requiredVotes New required number of votes.
    function updateRequiredVotes(uint256 _requiredVotes) external onlyOwner {
        require(_requiredVotes > 0 && _requiredVotes <= validators.length, "Invalid required votes");
        requiredVotes = _requiredVotes;
        emit RequiredVotesUpdated(_requiredVotes);
    }
    
    /// @notice Allows a validator to submit a new proposal.
    /// @param _description A short description of the proposal.
    /// @param _data Arbitrary data associated with the proposal.
    /// @return proposalId The unique ID of the submitted proposal.
    function submitProposal(string calldata _description, bytes calldata _data)
        external
        onlyValidator
        returns (uint256 proposalId)
    {
        proposalId = nextProposalId;
        nextProposalId++;
        
        // Create a new proposal in storage.
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.data = _data;
        newProposal.voteCount = 0;
        newProposal.consensusReached = false;
        
        emit ProposalSubmitted(proposalId, msg.sender, _description);
    }
    
    /// @notice Allows a validator to vote on an existing proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    function voteOnProposal(uint256 _proposalId)
        external
        onlyValidator
        nonReentrant
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.consensusReached, "Consensus already reached");
        require(!proposal.votes[msg.sender], "Already voted");
        
        proposal.votes[msg.sender] = true;
        proposal.voteCount++;
        
        emit ProposalVoted(_proposalId, msg.sender, proposal.voteCount);
        
        // Check if consensus is reached.
        if (proposal.voteCount >= requiredVotes) {
            proposal.consensusReached = true;
            emit ConsensusReached(_proposalId);
            // Optionally, execute associated proposal data here.
        }
    }
    
    /// @notice Retrieves details of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return id Proposal ID.
    /// @return proposer Address of the proposal submitter.
    /// @return description Proposal description.
    /// @return data Arbitrary proposal data.
    /// @return voteCount Number of votes received.
    /// @return consensusReached True if consensus has been reached.
    function getProposal(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            bytes memory data,
            uint256 voteCount,
            bool consensusReached
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.data,
            proposal.voteCount,
            proposal.consensusReached
        );
    }
}
