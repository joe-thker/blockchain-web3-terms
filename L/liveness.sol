// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract LivenessMonitor {
    address public oracle;
    uint256 public lastUpdate;
    uint256 public livenessTimeout = 1 hours;

    event OracleUpdated(uint256 timestamp);
    event LivenessFailed(uint256 currentTime);

    modifier onlyOracle() {
        require(msg.sender == oracle, "Not oracle");
        _;
    }

    constructor(address _oracle) {
        oracle = _oracle;
        lastUpdate = block.timestamp;
    }

    function update() external onlyOracle {
        lastUpdate = block.timestamp;
        emit OracleUpdated(lastUpdate);
    }

    function isLive() public view returns (bool) {
        return (block.timestamp - lastUpdate) < livenessTimeout;
    }

    function fallbackIfStale() external {
        if (!isLive()) {
            emit LivenessFailed(block.timestamp);
            // Trigger fallback logic here (e.g., pause protocol, revert to backup)
        }
    }
}
