// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Competitive Initial Bounty Offering (IBO)
/// @notice Admin approves tasks for users; rewards are distributed based on approved points.
contract CompetitiveIBO is Ownable {
    IERC20 public rewardToken;
    uint256 public totalApprovedPoints;
    uint256 public totalRewardPool;
    bool public claimingEnabled;

    mapping(address => uint256) public approvedPoints;
    mapping(address => bool) public claimed;

    event TaskApproved(address indexed user, uint256 points);
    event TokensClaimed(address indexed user, uint256 amount);
    event ClaimingToggled(bool status);

    constructor(address _token, uint256 _rewardPool) Ownable(msg.sender) {
        rewardToken = IERC20(_token);
        totalRewardPool = _rewardPool;
    }

    function approveTask(address user, uint256 points) external onlyOwner {
        approvedPoints[user] += points;
        totalApprovedPoints += points;
        emit TaskApproved(user, points);
    }

    function toggleClaiming(bool status) external onlyOwner {
        claimingEnabled = status;
        emit ClaimingToggled(status);
    }

    function claimTokens() external {
        require(claimingEnabled, "Claiming not enabled");
        require(!claimed[msg.sender], "Already claimed");
        uint256 points = approvedPoints[msg.sender];
        require(points > 0, "No approved points");
        uint256 reward = (points * totalRewardPool) / totalApprovedPoints;
        claimed[msg.sender] = true;
        rewardToken.transfer(msg.sender, reward);
        emit TokensClaimed(msg.sender, reward);
    }

    function depositRewardPool(uint256 amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);
        totalRewardPool += amount;
    }

    function withdrawUnclaimed(address to) external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(to, balance);
    }
}
