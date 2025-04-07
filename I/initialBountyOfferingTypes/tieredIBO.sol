// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Tiered Initial Bounty Offering (IBO)
/// @notice Bounties are assigned per tier/category and rewards are distributed proportionally per tier.
contract TieredIBO is Ownable {
    IERC20 public rewardToken;
    uint256 public totalRewardPool;
    bool public claimingEnabled;

    uint8 public constant NUM_CATEGORIES = 3;
    // category => total points
    mapping(uint8 => uint256) public totalPointsPerCategory;
    // user => (category => points)
    mapping(address => mapping(uint8 => uint256)) public userPoints;
    mapping(address => bool) public claimed;

    event BountyAssigned(address indexed user, uint8 category, uint256 points);
    event TokensClaimed(address indexed user, uint256 amount);
    event ClaimingToggled(bool status);

    constructor(address _token, uint256 _rewardPool) Ownable(msg.sender) {
        rewardToken = IERC20(_token);
        totalRewardPool = _rewardPool;
    }

    function assignBounty(address user, uint8 category, uint256 points) external onlyOwner {
        require(category > 0 && category <= NUM_CATEGORIES, "Invalid category");
        require(!claimed[user], "User already claimed");
        userPoints[user][category] += points;
        totalPointsPerCategory[category] += points;
        emit BountyAssigned(user, category, points);
    }

    function toggleClaiming(bool _status) external onlyOwner {
        claimingEnabled = _status;
        emit ClaimingToggled(_status);
    }

    function claimTokens() external {
        require(claimingEnabled, "Claiming not enabled");
        require(!claimed[msg.sender], "Already claimed");
        uint256 totalReward;
        // Distribute reward pool equally across categories
        uint256 rewardPerCategory = totalRewardPool / NUM_CATEGORIES;
        for (uint8 cat = 1; cat <= NUM_CATEGORIES; cat++) {
            uint256 userCatPoints = userPoints[msg.sender][cat];
            if (userCatPoints > 0 && totalPointsPerCategory[cat] > 0) {
                totalReward += (userCatPoints * rewardPerCategory) / totalPointsPerCategory[cat];
            }
        }
        claimed[msg.sender] = true;
        rewardToken.transfer(msg.sender, totalReward);
        emit TokensClaimed(msg.sender, totalReward);
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
