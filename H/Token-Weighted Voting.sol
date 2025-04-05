interface IERC20 {
    function balanceOf(address user) external view returns (uint256);
}

contract WeightedVoteDAG {
    IERC20 public token;

    struct Event {
        bytes32 hash;
        uint256 totalWeight;
        mapping(address => bool) voted;
    }

    mapping(bytes32 => Event) public events;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function vote(bytes32 hash) external {
        require(!events[hash].voted[msg.sender], "Already voted");
        uint256 weight = token.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        events[hash].totalWeight += weight;
        events[hash].voted[msg.sender] = true;
    }

    function getTotalWeight(bytes32 hash) external view returns (uint256) {
        return events[hash].totalWeight;
    }
}
