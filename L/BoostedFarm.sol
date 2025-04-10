// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title BoostedFarm
/// @notice Users earn more rewards based on boost multiplier
contract BoostedFarm {
    IERC20 public lp;
    IERC20 public reward;

    mapping(address => uint256) public stakeTime;
    mapping(address => uint256) public balance;
    mapping(address => uint256) public boost;

    uint256 public baseRate = 1e17; // 0.1 tokens per block per LP token

    constructor(address _lp, address _reward) {
        lp = IERC20(_lp);
        reward = IERC20(_reward);
    }

    function setBoost(address user, uint256 factor) external {
        // Example: 120 = 1.2x, 100 = 1.0x
        require(factor >= 100, "Minimum boost is 1.0x");
        boost[user] = factor;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        _claim(msg.sender);
        balance[msg.sender] += amount;
        stakeTime[msg.sender] = block.number;
        lp.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        require(balance[msg.sender] >= amount, "Insufficient balance");
        _claim(msg.sender);
        balance[msg.sender] -= amount;
        lp.transfer(msg.sender, amount);
    }

    function _claim(address user) internal {
        if (stakeTime[user] == 0) return;

        uint256 blocks = block.number - stakeTime[user];
        uint256 multiplier = boost[user] > 0 ? boost[user] : 100;

        uint256 rewardAmount = (blocks * baseRate * balance[user] * multiplier) / 1e4;
        stakeTime[user] = block.number;

        reward.transfer(user, rewardAmount);
    }
}
