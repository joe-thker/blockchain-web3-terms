contract GovernanceVulnerable {
    mapping(address => uint256) public votes;
    address public admin;

    function propose(address newAdmin) external {
        require(votes[msg.sender] > 1000, "Not enough voting power");
        admin = newAdmin; // ⚠️ Simple threshold, no delay or DAO controls
    }

    function vote(uint256 amount) external {
        votes[msg.sender] += amount;
    }
}
