contract PoolHashPower {
    mapping(address => uint256) public shares;
    uint256 public totalHashPower;

    function contribute(uint256 hashCount) external {
        require(hashCount > 0);
        shares[msg.sender] += hashCount;
        totalHashPower += hashCount;
    }

    function getMySharePercentage(address user) external view returns (uint256) {
        if (totalHashPower == 0) return 0;
        return (shares[user] * 1e18) / totalHashPower;
    }
}
