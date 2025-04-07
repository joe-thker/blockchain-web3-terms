// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Initial Bounty Offering (IBO) Contract
/// @notice Dynamically assigns and distributes tokens based on bounties
contract InitialBountyOffering is Ownable {
    IERC20 public rewardToken;
    uint256 public totalBountyPoints;
    uint256 public totalRewardPool;
    bool public claimingEnabled;

    struct Bounty {
        uint256 points;
        bool claimed;
    }

    mapping(address => Bounty) public bounties;

    event BountyAssigned(address indexed user, uint256 points);
    event TokensClaimed(address indexed user, uint256 amount);
    event ClaimingEnabled(bool status);

    constructor(address _token, uint256 _totalRewardPool) Ownable(msg.sender) {
        rewardToken = IERC20(_token);
        totalRewardPool = _totalRewardPool;
    }

    /// @notice Assign bounty points to a contributor
    function assignBounty(address user, uint256 points) external onlyOwner {
        require(!bounties[user].claimed, "Already claimed");
        totalBountyPoints += points;
        bounties[user].points += points;
        emit BountyAssigned(user, points);
    }

    /// @notice Enable or disable claiming
    function toggleClaiming(bool status) external onlyOwner {
        claimingEnabled = status;
        emit ClaimingEnabled(status);
    }

    /// @notice Contributors claim their token rewards based on points
    function claimTokens() external {
        require(claimingEnabled, "Claiming not active");
        Bounty storage bounty = bounties[msg.sender];
        require(!bounty.claimed, "Already claimed");
        require(bounty.points > 0, "No bounty assigned");

        uint256 reward = (bounty.points * totalRewardPool) / totalBountyPoints;
        bounty.claimed = true;
        rewardToken.transfer(msg.sender, reward);

        emit TokensClaimed(msg.sender, reward);
    }

    /// @notice Admin can deposit additional tokens to increase the reward pool
    function increaseRewardPool(uint256 amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);
        totalRewardPool += amount;
    }

    /// @notice Withdraw unclaimed tokens after campaign ends
    function withdrawUnclaimed(address to) external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(to, balance);
    }
}
