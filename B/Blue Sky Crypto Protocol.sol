// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlueSkyCryptoProtocol
/// @notice A decentralized platform for submitting and voting on innovative blockchain proposals.
contract BlueSkyCryptoProtocol {
    address public owner;
    uint256 public proposalCount;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteCount;
        bool finalized;
    }

    // Mapping from proposal ID to Proposal details.
    mapping(uint256 => Proposal) public proposals;
    // Mapping to track if an address has voted for a particular proposal.
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, uint256 newVoteCount);
    event ProposalFinalized(uint256 indexed proposalId, bool accepted);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the contract owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Submit a new proposal.
    /// @param _description A short description of the proposal.
    function submitProposal(string calldata _description) external {
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _description,
            voteCount: 0,
            finalized: false
        });
        emit ProposalSubmitted(proposalCount, msg.sender, _description);
        proposalCount++;
    }

    /// @notice Vote for an existing proposal.
    /// @param _proposalId The ID of the proposal to vote for.
    function voteForProposal(uint256 _proposalId) external {
        require(_proposalId < proposalCount, "Invalid proposal ID");
        require(!hasVoted[msg.sender][_proposalId], "Already voted for this proposal");
        require(!proposals[_proposalId].finalized, "Proposal already finalized");

        proposals[_proposalId].voteCount++;
        hasVoted[msg.sender][_proposalId] = true;

        emit ProposalVoted(_proposalId, msg.sender, proposals[_proposalId].voteCount);
    }

    /// @notice Finalize a proposal (only callable by the owner).
    /// @param _proposalId The ID of the proposal to finalize.
    function finalizeProposal(uint256 _proposalId) external onlyOwner {
        require(_proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.finalized, "Proposal already finalized");

        // For this simulation, we simply finalize the proposal.
        proposal.finalized = true;
        // The 'accepted' parameter can be expanded with additional logic.
        emit ProposalFinalized(_proposalId, true);
    }

    /// @notice Retrieve a proposal by its ID.
    /// @param _proposalId The ID of the proposal.
    /// @return The Proposal struct.
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        require(_proposalId < proposalCount, "Proposal does not exist");
        return proposals[_proposalId];
    }
}
