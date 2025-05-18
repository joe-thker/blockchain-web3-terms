// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract YieldFarmVault {
    IERC20 public immutable stakeToken;
    IERC20 public immutable rewardToken;

    uint256 public constant DURATION = 30 days;
    uint256 public totalStaked;
    uint256 public rewardRate;
    uint256 public lastUpdate;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;

    constructor(address _stakeToken, address _rewardToken, uint256 _totalReward) {
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _totalReward / DURATION;
        lastUpdate = block.timestamp;
    }

    modifier updateReward(address user) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdate = block.timestamp;
        rewards[user] = earned(user);
        userRewardPaid[user] = rewardPerTokenStored;
        _;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + (rewardRate * (block.timestamp - lastUpdate) * 1e18 / totalStaked);
    }

    function earned(address user) public view returns (uint256) {
        return (balances[user] * (rewardPerToken() - userRewardPaid[user]) / 1e18) + rewards[user];
    }

    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Zero stake");
        balances[msg.sender] += amount;
        totalStaked += amount;
        stakeToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Zero withdraw");
        balances[msg.sender] -= amount;
        totalStaked -= amount;
        stakeToken.transfer(msg.sender, amount);
    }

    function claim() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "Nothing to claim");
        rewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);
    }
}
