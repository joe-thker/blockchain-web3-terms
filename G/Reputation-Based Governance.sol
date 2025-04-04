contract ReputationGovernance {
    mapping(address => uint256) public reputation;
    mapping(uint256 => Proposal) public proposals;

    uint256 public proposalCount;

    struct Proposal {
        string description;
        uint256 repVotes;
    }

    function assignReputation(address user, uint256 points) external {
        reputation[user] += points;
    }

    function createProposal(string memory description) external returns (uint256) {
        proposals[proposalCount] = Proposal(description, 0);
        return proposalCount++;
    }

    function vote(uint256 proposalId) external {
        proposals[proposalId].repVotes += reputation[msg.sender];
    }
}
