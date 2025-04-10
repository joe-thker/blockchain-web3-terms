// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @notice ERC20 interface with required functions
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title Simple Liquidity Mining Reward Pool
contract LiquidityMining {
    IERC20 public lpToken;
    IERC20 public rewardToken;

    uint256 public rewardRatePerBlock = 1e18; // 1 reward token per block
    uint256 public lastRewardBlock;
    uint256 public accRewardPerShare;

    mapping(address => uint256) public userAmount;
    mapping(address => uint256) public rewardDebt;

    constructor(address _lpToken, address _rewardToken) {
        lpToken = IERC20(_lpToken);
        rewardToken = IERC20(_rewardToken);
        lastRewardBlock = block.number;
    }

    function updatePool() internal {
        uint256 lpSupply = lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 blocks = block.number - lastRewardBlock;
        uint256 reward = blocks * rewardRatePerBlock;
        accRewardPerShare += (reward * 1e12) / lpSupply;
        lastRewardBlock = block.number;
    }

    function deposit(uint256 amount) external {
        updatePool();

        if (userAmount[msg.sender] > 0) {
            uint256 pending = (userAmount[msg.sender] * accRewardPerShare) / 1e12 - rewardDebt[msg.sender];
            rewardToken.transfer(msg.sender, pending);
        }

        lpToken.transferFrom(msg.sender, address(this), amount);
        userAmount[msg.sender] += amount;
        rewardDebt[msg.sender] = (userAmount[msg.sender] * accRewardPerShare) / 1e12;
    }

    function withdraw(uint256 amount) external {
        updatePool();

        uint256 pending = (userAmount[msg.sender] * accRewardPerShare) / 1e12 - rewardDebt[msg.sender];
        rewardToken.transfer(msg.sender, pending);

        userAmount[msg.sender] -= amount;
        lpToken.transfer(msg.sender, amount);
        rewardDebt[msg.sender] = (userAmount[msg.sender] * accRewardPerShare) / 1e12;
    }
}
