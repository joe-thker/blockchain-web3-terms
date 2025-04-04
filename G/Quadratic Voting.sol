contract QuadraticGovernance {
    mapping(address => uint256) public tokenBalance;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    struct Proposal {
        string description;
        uint256 weightedVotes;
    }

    function createProposal(string memory description) external returns (uint256) {
        proposals[proposalCount] = Proposal(description, 0);
        return proposalCount++;
    }

    function vote(uint256 proposalId) external {
        uint256 tokens = tokenBalance[msg.sender];
        uint256 weight = sqrt(tokens);
        proposals[proposalId].weightedVotes += weight;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
