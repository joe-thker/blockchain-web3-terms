// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ClassicLPFarm
/// @notice Users stake LP tokens and earn a reward token at a fixed rate
contract ClassicLPFarm {
    IERC20 public lpToken;
    IERC20 public rewardToken;

    mapping(address => uint256) public staked;
    mapping(address => uint256) public lastUpdate;
    mapping(address => uint256) public rewards;

    uint256 public rewardRate = 1e18; // 1 token per block per LP token

    constructor(address _lp, address _reward) {
        lpToken = IERC20(_lp);
        rewardToken = IERC20(_reward);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        _updateReward(msg.sender);
        staked[msg.sender] += amount;
        lpToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        require(staked[msg.sender] >= amount, "Insufficient balance");
        _updateReward(msg.sender);
        staked[msg.sender] -= amount;
        lpToken.transfer(msg.sender, amount);
    }

    function claim() external {
        _updateReward(msg.sender);
        uint256 r = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, r);
    }

    function _updateReward(address user) internal {
        if (lastUpdate[user] > 0) {
            uint256 blocks = block.number - lastUpdate[user];
            uint256 reward = blocks * rewardRate * staked[user] / 1e18;
            rewards[user] += reward;
        }
        lastUpdate[user] = block.number;
    }
}
