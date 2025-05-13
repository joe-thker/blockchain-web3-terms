// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TPSModule - Measure and Limit Transactions Per Second by User or Contract

/// 📈 TPS Tracker
contract TPSTracker {
    mapping(address => uint256) public txCount;
    mapping(address => mapping(uint256 => uint256)) public perSecondCount;

    event Tracked(address indexed user, uint256 timestamp);

    function logTx() external {
        txCount[msg.sender]++;
        uint256 ts = block.timestamp;
        perSecondCount[msg.sender][ts]++;
        emit Tracked(msg.sender, ts);
    }

    function getTPS(address user, uint256 timestamp) external view returns (uint256) {
        return perSecondCount[user][timestamp];
    }
}

/// 🚀 High-Frequency Executor
contract HighTPSExecutor {
    TPSTracker public tracker;

    constructor(address _tracker) {
        tracker = TPSTracker(_tracker);
    }

    function executeMany(uint256 loops) external {
        for (uint256 i = 0; i < loops; i++) {
            tracker.logTx();
        }
    }
}

/// 🛑 Rate-Limited Vault (1 tx/sec/user)
contract RateLimitedVault {
    mapping(address => uint256) public lastTx;
    mapping(address => uint256) public balances;

    function deposit() external payable {
        require(block.timestamp > lastTx[msg.sender], "Rate limited");
        balances[msg.sender] += msg.value;
        lastTx[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 amt) external {
        require(block.timestamp > lastTx[msg.sender], "Rate limited");
        require(balances[msg.sender] >= amt, "Low balance");
        balances[msg.sender] -= amt;
        lastTx[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(amt);
    }
}

/// 🔓 TPS Attacker (TX Spammer)
interface ITPSTracker {
    function logTx() external;
}

contract TPSAttacker {
    function spam(ITPSTracker tracker, uint256 count) external {
        for (uint256 i = 0; i < count; i++) {
            tracker.logTx();
        }
    }
}
