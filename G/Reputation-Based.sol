contract ReputationToken {
    mapping(address => uint256) public reputation;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function award(address user, uint256 amount) external {
        require(msg.sender == admin, "Only admin");
        reputation[user] += amount;
    }

    function getVotingPower(address user) external view returns (uint256) {
        return reputation[user];
    }
}
