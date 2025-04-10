contract OnRewardHook {
    mapping(address => uint256) public userBoost;

    function onRewardClaim(address user, uint256 rewardAmount) external view returns (uint256) {
        uint256 boost = userBoost[user];
        return rewardAmount + (rewardAmount * boost) / 100;
    }

    function setBoost(address user, uint256 percent) external {
        userBoost[user] = percent;
    }
}
