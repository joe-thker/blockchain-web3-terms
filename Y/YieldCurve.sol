// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract YieldCurveVault {
    IERC20 public immutable stakeToken;
    address public immutable admin;

    struct LockInfo {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        bool claimed;
    }

    mapping(address => LockInfo[]) public locks;
    mapping(uint256 => uint256) public yieldRates; // duration → APR in basis points (e.g., 500 = 5%)

    event Staked(address indexed user, uint256 amount, uint256 duration);
    event Claimed(address indexed user, uint256 index, uint256 reward);

    constructor(address _token) {
        stakeToken = IERC20(_token);
        admin = msg.sender;

        // Set example curve: longer = higher yield
        yieldRates[30 days] = 300;   // 3%
        yieldRates[90 days] = 700;   // 7%
        yieldRates[180 days] = 1500; // 15%
    }

    function stake(uint256 amount, uint256 duration) external {
        require(yieldRates[duration] > 0, "Invalid lock duration");
        require(amount > 0, "Zero stake");

        stakeToken.transferFrom(msg.sender, address(this), amount);

        locks[msg.sender].push(LockInfo({
            amount: amount,
            startTime: block.timestamp,
            duration: duration,
            claimed: false
        }));

        emit Staked(msg.sender, amount, duration);
    }

    function claim(uint256 index) external {
        LockInfo storage info = locks[msg.sender][index];
        require(!info.claimed, "Already claimed");
        require(block.timestamp >= info.startTime + info.duration, "Lock active");

        uint256 apr = yieldRates[info.duration];
        uint256 reward = (info.amount * apr * info.duration) / (365 days * 10_000);

        info.claimed = true;
        stakeToken.transfer(msg.sender, info.amount + reward);

        emit Claimed(msg.sender, index, reward);
    }

    function setYield(uint256 duration, uint256 aprBps) external {
        require(msg.sender == admin, "Not admin");
        yieldRates[duration] = aprBps;
    }

    function getLocks(address user) external view returns (LockInfo[] memory) {
        return locks[user];
    }
}
