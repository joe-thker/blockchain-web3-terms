contract ProfitToken {
    mapping(address => uint256) public deposits;

    function stake() external payable {
        deposits[msg.sender] += msg.value;
    }

    function claimReward() external {
        uint256 reward = deposits[msg.sender] / 10;
        payable(msg.sender).transfer(reward);
    }
}
