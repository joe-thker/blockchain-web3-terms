// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ThroughputModule - Smart Contract Simulation for Throughput Handling, Attack, and Defense

// ==============================
// 🔓 Vulnerable Bulk Executor
// ==============================
contract BulkExecutor {
    event Executed(uint256 indexed id, address user);

    uint256 public taskCounter;

    function executeMany(uint256 count) external {
        for (uint256 i = 0; i < count; i++) {
            _executeTask(msg.sender);
        }
    }

    function _executeTask(address user) internal {
        taskCounter++;
        emit Executed(taskCounter, user);
    }
}

// ==============================
// 🔓 Attack: Block Saturation Flood
// ==============================
interface IBulkExecutor {
    function executeMany(uint256) external;
}

contract FloodAttack {
    IBulkExecutor public target;

    constructor(address _target) {
        target = IBulkExecutor(_target);
    }

    function flood(uint256 count) external {
        target.executeMany(count);
    }
}

// ==============================
// 🔐 Safe Bulk Executor With Limits
// ==============================
contract SafeBulkExecutor {
    event Executed(uint256 indexed id, address user);

    uint256 public taskCounter;
    uint256 public constant MAX_BATCH = 100;

    mapping(address => uint256) public lastBatchBlock;

    function executeMany(uint256 count) external {
        require(count <= MAX_BATCH, "Batch too large");
        require(block.number > lastBatchBlock[msg.sender], "One batch per block");

        for (uint256 i = 0; i < count; i++) {
            if (gasleft() < 50_000) break;
            _executeTask(msg.sender);
        }

        lastBatchBlock[msg.sender] = block.number;
    }

    function _executeTask(address user) internal {
        taskCounter++;
        emit Executed(taskCounter, user);
    }
}

// ==============================
// 📊 Throughput Meter Tracker
// ==============================
contract ThroughputMeter {
    mapping(address => uint256) public callCount;
    mapping(address => uint256) public lastReset;
    uint256 public window = 20;

    function record(address user) external {
        if (block.number > lastReset[user] + window) {
            callCount[user] = 0;
            lastReset[user] = block.number;
        }
        callCount[user]++;
    }

    function getThroughput(address user) external view returns (uint256) {
        return callCount[user];
    }
}
