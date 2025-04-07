// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Basic Initial Bounty Offering (IBO)
/// @notice Admin assigns bounty points; users claim rewards proportionally.
contract BasicIBO is Ownable {
    IERC20 public rewardToken;
    uint256 public totalBountyPoints;
    uint256 public totalRewardPool;
    bool public claimingEnabled;

    mapping(address => uint256) public bountyPoints;
    mapping(address => bool) public claimed;

    event BountyAssigned(address indexed user, uint256 points);
    event TokensClaimed(address indexed user, uint256 amount);
    event ClaimingToggled(bool status);

    constructor(address _token, uint256 _rewardPool) Ownable(msg.sender) {
        rewardToken = IERC20(_token);
        totalRewardPool = _rewardPool;
    }

    function assignBounty(address user, uint256 points) external onlyOwner {
        require(!claimed[user], "User already claimed");
        bountyPoints[user] += points;
        totalBountyPoints += points;
        emit BountyAssigned(user, points);
    }

    function toggleClaiming(bool _status) external onlyOwner {
        claimingEnabled = _status;
        emit ClaimingToggled(_status);
    }

    function claimTokens() external {
        require(claimingEnabled, "Claiming not enabled");
        require(!claimed[msg.sender], "Already claimed");
        uint256 points = bountyPoints[msg.sender];
        require(points > 0, "No bounty assigned");

        uint256 reward = (points * totalRewardPool) / totalBountyPoints;
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
