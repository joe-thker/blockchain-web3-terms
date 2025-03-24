// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title HostedCloudMining
/// @notice A simulation of hosted cloud mining where users deposit funds and earn rewards continuously.
contract HostedCloudMining {
    address public owner;
    // Reward rate: mined tokens per wei per second (for simulation)
    uint256 public rewardRate;

    struct DepositInfo {
        uint256 amount;
        uint256 lastClaimed;
    }
    mapping(address => DepositInfo) public deposits;

    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event RewardClaimed(address indexed user, uint256 reward, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    /// @notice Deposit funds to start earning mining rewards.
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be > 0");
        DepositInfo storage info = deposits[msg.sender];
        // Claim any accrued reward before adding new deposit
        if (info.amount > 0) {
            _claimReward(msg.sender);
        }
        info.amount += msg.value;
        info.lastClaimed = block.timestamp;
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    /// @notice Internal function to calculate and claim rewards.
    function _claimReward(address user) internal {
        DepositInfo storage info = deposits[user];
        uint256 elapsed = block.timestamp - info.lastClaimed;
        uint256 reward = info.amount * rewardRate * elapsed;
        info.lastClaimed = block.timestamp;
        emit RewardClaimed(user, reward, block.timestamp);
        // In a production system, rewards might be minted as tokens.
    }

    /// @notice Allows a user to claim accrued rewards.
    function claimReward() external {
        require(deposits[msg.sender].amount > 0, "No deposit found");
        _claimReward(msg.sender);
    }
}
