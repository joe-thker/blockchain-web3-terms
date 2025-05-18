// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title LamboLocker - Rewards diamond hands, penalizes Lambo dumpers
contract LamboLocker {
    IERC20 public immutable token;
    uint256 public immutable lockPeriod;
    uint256 public immutable earlyPenaltyRate;
    uint256 public immutable bonusRate;

    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        bool claimed;
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 payout, uint256 bonus, uint256 penalty);

    constructor(address _token, uint256 _lockTime, uint256 _penaltyRate, uint256 _bonusRate) {
        token = IERC20(_token);
        lockPeriod = _lockTime; // e.g., 30 days
        earlyPenaltyRate = _penaltyRate; // e.g., 10% = 0.1e18
        bonusRate = _bonusRate; // e.g., 5% = 0.05e18
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Zero stake");
        require(stakes[msg.sender].amount == 0, "Already staked");

        token.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] = StakeInfo({
            amount: amount,
            timestamp: block.timestamp,
            claimed: false
        });

        emit Staked(msg.sender, amount);
    }

    function withdraw() external {
        StakeInfo storage s = stakes[msg.sender];
        require(!s.claimed, "Already withdrawn");
        require(s.amount > 0, "No stake");

        uint256 reward;
        uint256 penalty;
        uint256 payout = s.amount;
        uint256 timeHeld = block.timestamp - s.timestamp;

        if (timeHeld < lockPeriod) {
            penalty = (s.amount * earlyPenaltyRate) / 1e18;
            payout -= penalty;
        } else {
            reward = (s.amount * bonusRate) / 1e18;
            payout += reward;
        }

        s.claimed = true;
        if (penalty > 0) token.transfer(address(0), penalty); // burn
        token.transfer(msg.sender, payout);

        emit Withdrawn(msg.sender, payout, reward, penalty);
    }

    function getTimeHeld(address user) external view returns (uint256) {
        return block.timestamp - stakes[user].timestamp;
    }
}

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}
