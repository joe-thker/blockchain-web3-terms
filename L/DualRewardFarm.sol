// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title DualRewardFarm
/// @notice Users stake LP tokens and earn two reward tokens
contract DualRewardFarm {
    IERC20 public lp;
    IERC20 public rewardA;
    IERC20 public rewardB;

    mapping(address => uint256) public stakeTime;
    mapping(address => uint256) public balance;

    uint256 public rateA = 1e17; // 0.1 A per block
    uint256 public rateB = 5e16; // 0.05 B per block

    constructor(address _lp, address _a, address _b) {
        lp = IERC20(_lp);
        rewardA = IERC20(_a);
        rewardB = IERC20(_b);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        _claim(msg.sender);
        balance[msg.sender] += amount;
        stakeTime[msg.sender] = block.number;
        lp.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        require(balance[msg.sender] >= amount, "Not enough staked");
        _claim(msg.sender);
        balance[msg.sender] -= amount;
        lp.transfer(msg.sender, amount);
    }

    function _claim(address user) internal {
        uint256 blocks = block.number - stakeTime[user];
        uint256 amount = balance[user];

        uint256 aReward = blocks * rateA * amount / 1e18;
        uint256 bReward = blocks * rateB * amount / 1e18;

        if (aReward > 0) rewardA.transfer(user, aReward);
        if (bReward > 0) rewardB.transfer(user, bReward);

        stakeTime[user] = block.number;
    }
}
