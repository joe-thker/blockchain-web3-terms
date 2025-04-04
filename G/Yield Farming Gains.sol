// YieldFarmingGains.sol
pragma solidity ^0.8.20;

contract YieldFarmingGains {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public yieldEarned;

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
    }

    function simulateYield(address user, uint256 amount) external {
        yieldEarned[user] += amount;
    }

    function claimYield() external {
        uint256 reward = yieldEarned[msg.sender];
        yieldEarned[msg.sender] = 0;
        payable(msg.sender).transfer(reward);
    }
}
