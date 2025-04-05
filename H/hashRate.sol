// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HashPowerTracker {
    struct Miner {
        uint256 hashesSubmitted;
        uint256 lastSubmit;
    }

    mapping(address => Miner) public miners;
    address[] public minerList;

    uint256 public totalHashes;

    event HashSubmitted(address indexed miner, uint256 count);
    event HashRateUpdated(address indexed miner, uint256 rateHps);

    /// @notice Submit a number of hashes (simulated)
    function submitHashes(uint256 hashCount) external {
        require(hashCount > 0, "Must submit at least one hash");

        Miner storage m = miners[msg.sender];

        if (m.hashesSubmitted == 0) {
            minerList.push(msg.sender);
        }

        m.hashesSubmitted += hashCount;

        uint256 timeElapsed = block.timestamp - m.lastSubmit;
        if (timeElapsed > 0) {
            uint256 rate = hashCount / timeElapsed; // hashes per second
            emit HashRateUpdated(msg.sender, rate);
        }

        m.lastSubmit = block.timestamp;
        totalHashes += hashCount;

        emit HashSubmitted(msg.sender, hashCount);
    }

    function getMinerStats(address user) external view returns (uint256 total, uint256 lastTime) {
        return (miners[user].hashesSubmitted, miners[user].lastSubmit);
    }

    function getTotalHashes() external view returns (uint256) {
        return totalHashes;
    }

    function getMinerList() external view returns (address[] memory) {
        return minerList;
    }
}
