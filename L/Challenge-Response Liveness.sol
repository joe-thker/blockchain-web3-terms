contract ChallengeResponseLiveness {
    address public challenged;
    uint256 public challengeStarted;
    uint256 public timeout = 1 days;

    function startChallenge(address user) external {
        challenged = user;
        challengeStarted = block.timestamp;
    }

    function respondToChallenge() external {
        require(msg.sender == challenged, "Not challenged user");
        require(block.timestamp <= challengeStarted + timeout, "Too late");
        challenged = address(0);
    }

    function isDefaulted() external view returns (bool) {
        return challenged != address(0) && block.timestamp > challengeStarted + timeout;
    }
}
