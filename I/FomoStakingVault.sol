// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FomoStakingVault {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakeTime;

    function stake() external payable {
        require(msg.value > 0, "Send ETH");
        balances[msg.sender] += msg.value;
        stakeTime[msg.sender] = block.timestamp;
    }

    function claimReward() external {
        uint256 staked = balances[msg.sender];
        require(staked > 0, "No stake");

        uint256 timeElapsed = block.timestamp - stakeTime[msg.sender];
        uint256 reward = (staked * (30 days - timeElapsed)) / (30 days); // Decreases over 30d
        balances[msg.sender] = 0;

        payable(msg.sender).transfer(staked + reward);
    }

    receive() external payable {}
}
