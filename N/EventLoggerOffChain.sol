// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventLoggerOffChain
 * @notice Emits events recording arbitrary payloads for off‑chain consumption.
 *         No on‑chain storage beyond the logs.
 */
contract EventLoggerOffChain {
    /// @notice Emitted when a new record is logged.
    event RecordLogged(address indexed sender, bytes32 indexed recordId, string payload, uint256 timestamp);

    /**
     * @notice Log an arbitrary string payload with an id.
     * @param recordId   A client‑provided identifier for the record.
     * @param payload    The data to log (e.g. JSON, IPFS hash).
     */
    function logRecord(bytes32 recordId, string calldata payload) external {
        emit RecordLogged(msg.sender, recordId, payload, block.timestamp);
    }
}
