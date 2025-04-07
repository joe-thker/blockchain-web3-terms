// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TimeLimitedIBO
/// @notice Bounties have expiration dates; rewards can only be claimed before expiry.
contract TimeLimitedIBO is Ownable {
    IERC20 public rewardToken;
    uint256 public totalRewardPool;
    bool public claimingEnabled;

    struct Bounty {
        uint256 points;
        uint256 expiry;
        bool claimed;
    }

    mapping(address => Bounty) public bounties;

    event BountyAssigned(address indexed user, uint256 points, uint256 expiry);
    event TokensClaimed(address indexed user, uint256 amount);
    event ClaimingToggled(bool status);

    constructor(address _token, uint256 _rewardPool) Ownable(msg.sender) {
        rewardToken = IERC20(_token);
        totalRewardPool = _rewardPool;
    }

    /// @notice Assign bounty points with a time limit (duration in seconds)
    function assignBounty(address user, uint256 points, uint256 duration) external onlyOwner {
        require(bounties[user].points == 0, "Bounty already assigned");
        uint256 expiryTime = block.timestamp + duration;
        bounties[user] = Bounty(points, expiryTime, false);
        emit BountyAssigned(user, points, expiryTime);
    }

    function toggleClaiming(bool _status) external onlyOwner {
        claimingEnabled = _status;
        emit ClaimingToggled(_status);
    }

    function claimTokens() external {
        require(claimingEnabled, "Claiming not enabled");
        Bounty storage bounty = bounties[msg.sender];
        require(!bounty.claimed, "Already claimed");
        require(bounty.points > 0, "No bounty assigned");
        require(block.timestamp <= bounty.expiry, "Bounty expired");

        // In this simple model, the reward equals the entire reward pool.
        // (For multiple users, you would calculate the reward proportionally.)
        uint256 reward = totalRewardPool;
        bounty.claimed = true;
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
