// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Minimal interface for an ERC20 used for community-based voting.
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @title DualGovernance
/// @notice A dynamic, optimized contract implementing a two-chamber governance model:
///  1) A Council that votes "one address, one vote."
///  2) A Community that votes based on ERC20 token balances.
/// A proposal passes only if both thresholds are met.
contract DualGovernance is Ownable, ReentrancyGuard {
    // The ERC20 token for community-based voting.
    IERC20 public communityToken;

    // Mapping of council addresses => boolean indicating membership.
    mapping(address => bool) public isCouncilMember;
    uint256 public totalCouncilMembers;

    // e.g., councilThreshold = 3 => need 3 "yes" from council
    // communityThreshold = total token balance needed for acceptance (simplistic approach).
    uint256 public councilThreshold;
    uint256 public communityThreshold;

    /// @notice A proposal data structure for dual governance.
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        // Council voting
        uint256 councilYesCount;
        mapping(address => bool) councilHasVoted;
        // Community voting
        uint256 communityYesBalance;
        mapping(address => uint256) communityVotedBalance;
        bool accepted;
        bool active;
        uint256 createdAt;
    }

    Proposal[] public proposals;
    uint256 public nextProposalId;

    // --- Events ---
    event CouncilMemberAdded(address indexed member);
    event CouncilMemberRemoved(address indexed member);
    event CouncilThresholdUpdated(uint256 newCouncilThreshold);
    event CommunityThresholdUpdated(uint256 newCommunityThreshold);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event CouncilVoted(uint256 indexed proposalId, address indexed voter, bool yes);
    event CommunityVoted(uint256 indexed proposalId, address indexed voter, uint256 tokenBalance);
    event ProposalAccepted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    /// @notice Constructor sets the ERC20 community token and initial thresholds. Deployer is owner.
    /// @param _communityToken The ERC20 token used for community-based voting.
    /// @param _councilThreshold The number of council yes votes required.
    /// @param _communityThreshold The total token yes-balance required for acceptance.
    constructor(
        address _communityToken,
        uint256 _councilThreshold,
        uint256 _communityThreshold
    )
        Ownable(msg.sender)
    {
        require(_communityToken != address(0), "Invalid token address");
        require(_councilThreshold > 0, "Council threshold must be > 0");
        require(_communityThreshold > 0, "Community threshold must be > 0");
        communityToken = IERC20(_communityToken);
        councilThreshold = _councilThreshold;
        communityThreshold = _communityThreshold;
    }

    // ------------------------------------------------------------------------
    // Owner (Admin) Functions
    // ------------------------------------------------------------------------

    /// @notice Adds a new council member.
    /// @param member The address to add.
    function addCouncilMember(address member) external onlyOwner {
        require(member != address(0), "Invalid address");
        require(!isCouncilMember[member], "Already a council member");
        isCouncilMember[member] = true;
        totalCouncilMembers++;
        emit CouncilMemberAdded(member);
    }

    /// @notice Removes a council member.
    /// @param member The address to remove.
    function removeCouncilMember(address member) external onlyOwner {
        require(isCouncilMember[member], "Not a council member");
        isCouncilMember[member] = false;
        totalCouncilMembers--;
        emit CouncilMemberRemoved(member);
    }

    /// @notice Updates the number of council yes votes required for acceptance.
    /// @param newThreshold The new council threshold.
    function updateCouncilThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Must be > 0");
        councilThreshold = newThreshold;
        emit CouncilThresholdUpdated(newThreshold);
    }

    /// @notice Updates the total token yes-balance needed for acceptance.
    /// @param newThreshold The new community threshold.
    function updateCommunityThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Must be > 0");
        communityThreshold = newThreshold;
        emit CommunityThresholdUpdated(newThreshold);
    }

    // ------------------------------------------------------------------------
    // Proposals
    // ------------------------------------------------------------------------

    /// @notice Creates a new proposal. Anyone can create a proposal.
    /// @param description A text describing the proposal.
    /// @return proposalId The ID of the newly created proposal.
    function createProposal(string calldata description)
        external
        nonReentrant
        returns (uint256 proposalId)
    {
        require(bytes(description).length > 0, "Description cannot be empty");
        proposalId = nextProposalId++;
        proposals.push();
        Proposal storage p = proposals[proposalId];
        p.id = proposalId;
        p.proposer = msg.sender;
        p.description = description;
        p.accepted = false;
        p.active = true;
        p.createdAt = block.timestamp;

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /// @notice A council member votes yes on a proposal. 
    /// @param proposalId The ID of the proposal to vote on.
    function councilVoteYes(uint256 proposalId) external nonReentrant {
        require(proposalId < proposals.length, "Invalid proposalId");
        Proposal storage p = proposals[proposalId];
        require(p.active, "Proposal not active");
        require(!p.accepted, "Proposal already accepted");
        require(isCouncilMember[msg.sender], "Not a council member");
        require(!p.councilHasVoted[msg.sender], "Already voted");

        p.councilHasVoted[msg.sender] = true;
        p.councilYesCount++;

        emit CouncilVoted(proposalId, msg.sender, true);

        _checkProposalAcceptance(p);
    }

    /// @notice A community user votes yes based on their token balance at the time.
    /// @param proposalId The ID of the proposal.
    function communityVoteYes(uint256 proposalId) external nonReentrant {
        require(proposalId < proposals.length, "Invalid proposalId");
        Proposal storage p = proposals[proposalId];
        require(p.active, "Proposal not active");
        require(!p.accepted, "Proposal already accepted");
        require(p.communityVotedBalance[msg.sender] == 0, "Already voted");

        uint256 bal = communityToken.balanceOf(msg.sender);
        require(bal > 0, "No token balance to vote with");

        p.communityVotedBalance[msg.sender] = bal;
        p.communityYesBalance += bal;

        emit CommunityVoted(proposalId, msg.sender, bal);

        _checkProposalAcceptance(p);
    }

    /// @notice The proposal creator can cancel it if not accepted yet.
    /// @param proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 proposalId) external nonReentrant {
        require(proposalId < proposals.length, "Invalid proposalId");
        Proposal storage p = proposals[proposalId];
        require(p.active, "Proposal not active");
        require(!p.accepted, "Already accepted");
        require(p.proposer == msg.sender, "Not proposal creator");

        p.active = false;
        emit ProposalCanceled(proposalId);
    }

    // ------------------------------------------------------------------------
    // Internal
    // ------------------------------------------------------------------------

    /// @notice Checks if both the council and community thresholds are met. If so, marks accepted.
    /// @param p The proposal struct reference.
    function _checkProposalAcceptance(Proposal storage p) internal {
        if (p.councilYesCount >= councilThreshold) {
            if (p.communityYesBalance >= communityThreshold) {
                p.accepted = true;
                emit ProposalAccepted(p.id);
            }
        }
    }

    // ------------------------------------------------------------------------
    // View Functions
    // ------------------------------------------------------------------------

    /// @notice Returns total proposals ever created (including canceled/accepted).
    /// @return The length of the proposals array.
    function totalProposals() external view returns (uint256) {
        return proposals.length;
    }

    /**
     * @notice Retrieves details of a proposal by ID.
     * @param proposalId The ID of the proposal.
     * @return id The proposal's ID.
     * @return proposer The address that created the proposal.
     * @return description The text describing the proposal.
     * @return councilYesCount How many council members have voted yes.
     * @return communityYesBalance The sum of the community token balances that voted yes.
     * @return accepted Whether the proposal has been accepted or not.
     * @return active Whether the proposal is still active (not canceled or accepted).
     * @return createdAt The timestamp when the proposal was created.
     */
    function getProposal(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            uint256 councilYesCount,
            uint256 communityYesBalance,
            bool accepted,
            bool active,
            uint256 createdAt
        )
    {
        require(proposalId < proposals.length, "Invalid proposalId");
        Proposal storage p = proposals[proposalId];
        return (
            p.id,
            p.proposer,
            p.description,
            p.councilYesCount,
            p.communityYesBalance,
            p.accepted,
            p.active,
            p.createdAt
        );
    }
}
