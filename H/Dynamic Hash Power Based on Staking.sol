contract DynamicHashPower {
    mapping(address => uint256) public stake;
    mapping(address => uint256) public power;

    function stakeTokens(uint256 amount) external {
        stake[msg.sender] += amount;
        power[msg.sender] = computeHashPower(stake[msg.sender]);
    }

    function computeHashPower(uint256 staked) internal pure returns (uint256) {
        return staked * 2; // Example: 1 stake = 2 hash units
    }

    function getMyPower() external view returns (uint256) {
        return power[msg.sender];
    }
}
