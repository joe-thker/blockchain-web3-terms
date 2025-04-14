// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OracleNetworkLatency {
    uint256 public latency; // measured latency in seconds
    address public oracle;

    event LatencyUpdated(uint256 newLatency);

    constructor(address _oracle) {
        oracle = _oracle;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Not authorized: oracle only");
        _;
    }

    /// @notice Called by the oracle to update the on‑chain latency.
    function updateLatency(uint256 newLatency) external onlyOracle {
        latency = newLatency;
        emit LatencyUpdated(newLatency);
    }
}
