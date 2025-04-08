// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title InitialStakePoolOffering (ISPO)
/// @notice Users stake ERC20 tokens to earn project tokens instead of regular staking rewards.
contract InitialStakePoolOffering is Ownable {
    IERC20 public stakeToken;     // Token being staked (e.g., ADA, ETH, USDC)
    IERC20 public rewardToken;    // Project token being distributed
    uint256 public rewardPool;    // Total project tokens to distribute

    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalStaked;

    mapping(address => uint256) public userStaked;
    mapping(address => bool) public hasClaimed;

    event Staked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 reward);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        address _stakeToken,
        address _rewardToken,
        uint256 _rewardPool,
        uint256 _startTime,
        uint256 _endTime
    ) Ownable(msg.sender) {
        require(_startTime < _endTime, "Invalid ISPO window");
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        rewardPool = _rewardPool;
        startTime = _startTime;
        endTime = _endTime;
    }

    /// @notice Stake base tokens during ISPO period
    function stake(uint256 amount) external {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "ISPO not active");
        require(amount > 0, "Amount must be > 0");

        stakeToken.transferFrom(msg.sender, address(this), amount);
        userStaked[msg.sender] += amount;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    /// @notice Claim project tokens after ISPO ends
    function claim() external {
        require(block.timestamp > endTime, "ISPO still active");
        require(userStaked[msg.sender] > 0, "Nothing staked");
        require(!hasClaimed[msg.sender], "Already claimed");

        uint256 userAmount = userStaked[msg.sender];
        uint256 reward = (userAmount * rewardPool) / totalStaked;

        hasClaimed[msg.sender] = true;
        rewardToken.transfer(msg.sender, reward);

        emit Claimed(msg.sender, reward);
    }

    /// @notice Users can optionally withdraw their stake after ISPO ends
    function withdrawStake() external {
        require(block.timestamp > endTime, "ISPO still active");
        uint256 amount = userStaked[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        userStaked[msg.sender] = 0;
        stakeToken.transfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    /// @notice Recover leftover project tokens
    function recoverUnclaimed(address to) external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(to, balance);
    }
}
