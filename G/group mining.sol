// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Group Mining Pool (Simulated)
contract GroupMiningPool {
    address public owner;
    uint256 public totalShares;
    uint256 public rewardPool;

    mapping(address => uint256) public shares;
    mapping(address => uint256) public payouts;

    event ShareSubmitted(address indexed miner, uint256 share);
    event RewardDeposited(uint256 amount);
    event RewardClaimed(address indexed miner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only pool owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Simulated mining work submission
    function submitWork(uint256 share) external {
        require(share > 0, "Share must be positive");

        shares[msg.sender] += share;
        totalShares += share;

        emit ShareSubmitted(msg.sender, share);
    }

    /// @notice Owner deposits mining rewards into pool
    function depositReward() external payable onlyOwner {
        require(msg.value > 0, "No reward");
        rewardPool += msg.value;

        emit RewardDeposited(msg.value);
    }

    /// @notice Claim your share of the pool
    function claimReward() external {
        uint256 userShare = shares[msg.sender];
        require(userShare > 0, "No shares");

        uint256 amount = (userShare * rewardPool) / totalShares;
        require(amount > 0, "Nothing to claim");

        // Reset miner's shares and update pool
        totalShares -= userShare;
        rewardPool -= amount;
        shares[msg.sender] = 0;
        payouts[msg.sender] += amount;

        payable(msg.sender).transfer(amount);
        emit RewardClaimed(msg.sender, amount);
    }

    /// @notice View pending reward for user
    function pendingReward(address user) external view returns (uint256) {
        if (totalShares == 0) return 0;
        return (shares[user] * rewardPool) / totalShares;
    }

    receive() external payable {
        rewardPool += msg.value;
        emit RewardDeposited(msg.value);
    }
}
