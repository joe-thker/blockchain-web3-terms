// StakingGains.sol
pragma solidity ^0.8.20;

contract StakingGains {
    mapping(address => uint256) public staked;
    mapping(address => uint256) public lastClaimed;

    function stake() external payable {
        staked[msg.sender] += msg.value;
        lastClaimed[msg.sender] = block.timestamp;
    }

    function calculateReward(address user) public view returns (uint256) {
        uint256 time = block.timestamp - lastClaimed[user];
        return (staked[user] * time) / 1 days / 100; // 1% daily
    }

    function claim() external {
        uint256 reward = calculateReward(msg.sender);
        lastClaimed[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(reward);
    }
}
