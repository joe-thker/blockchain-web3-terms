contract VirtualHashPowerGame {
    mapping(address => uint256) public virtualPower;
    uint256 public constant rewardPerHash = 1e16; // 0.01 token

    event Mined(address user, uint256 reward);

    function stakePower(uint256 amount) external {
        virtualPower[msg.sender] += amount;
    }

    function mine() external {
        uint256 reward = virtualPower[msg.sender] * rewardPerHash;
        require(reward > 0, "No power");
        emit Mined(msg.sender, reward);
    }
}
