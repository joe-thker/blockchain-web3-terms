contract ForkGovernor {
    bool public hardForkPassed;
    uint256 public yesVotes;
    uint256 public noVotes;

    mapping(address => bool) public voted;

    function vote(bool support) external {
        require(!voted[msg.sender], "Already voted");
        voted[msg.sender] = true;

        if (support) yesVotes++;
        else noVotes++;

        if (yesVotes >= 5) { // example threshold
            hardForkPassed = true;
        }
    }
}
