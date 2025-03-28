// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ConsumerPriceIndex
/// @notice This contract maintains a historical record of the Consumer Price Index (CPI).
/// The owner can update the CPI value, and each update is recorded along with a timestamp.
/// This design is dynamic (supports multiple updates), optimized (stores only necessary records),
/// and secure (using Ownable and ReentrancyGuard).
contract ConsumerPriceIndex is Ownable, ReentrancyGuard {
    // CPI values are stored with fixed decimals (e.g. scaled by 1e18)
    uint256 public constant DECIMALS = 1e18;

    struct CPIRecord {
        uint256 timestamp; // time of update
        uint256 cpi;       // CPI value (scaled by DECIMALS)
    }

    CPIRecord[] private records;

    event CPIUpdated(uint256 timestamp, uint256 cpi);

    /// @notice Constructor sets the initial CPI value.
    /// @param initialCPI The initial CPI value (scaled by DECIMALS).
    constructor(uint256 initialCPI) Ownable(msg.sender) {
        require(initialCPI > 0, "Initial CPI must be positive");
        records.push(CPIRecord({
            timestamp: block.timestamp,
            cpi: initialCPI
        }));
        emit CPIUpdated(block.timestamp, initialCPI);
    }

    /// @notice Allows the owner to update the CPI value.
    /// @param newCPI The new CPI value (scaled by DECIMALS).
    function updateCPI(uint256 newCPI) external onlyOwner nonReentrant {
        require(newCPI > 0, "CPI must be positive");
        CPIRecord storage lastRecord = records[records.length - 1];
        require(newCPI != lastRecord.cpi, "New CPI is identical to current CPI");
        records.push(CPIRecord({
            timestamp: block.timestamp,
            cpi: newCPI
        }));
        emit CPIUpdated(block.timestamp, newCPI);
    }

    /// @notice Returns the current CPI value.
    /// @return The most recent CPI value (scaled by DECIMALS).
    function getCurrentCPI() external view returns (uint256) {
        return records[records.length - 1].cpi;
    }

    /// @notice Returns the CPI record at a given index.
    /// @param index The index of the record (0-based).
    /// @return timestamp The timestamp of the record.
    /// @return cpi The CPI value at that time (scaled by DECIMALS).
    function getCPIRecord(uint256 index) external view returns (uint256 timestamp, uint256 cpi) {
        require(index < records.length, "Index out of bounds");
        CPIRecord storage record = records[index];
        return (record.timestamp, record.cpi);
    }

    /// @notice Returns the total number of CPI records stored.
    /// @return The count of CPI updates.
    function getRecordCount() external view returns (uint256) {
        return records.length;
    }

    /// @notice Computes the inflation rate between two CPI records.
    /// @param index1 The index of the earlier record.
    /// @param index2 The index of the later record (must be greater than index1).
    /// @return inflationRate The inflation rate as a percentage (scaled by DECIMALS).
    /// For example, a result of 0.05 * DECIMALS represents 5% inflation.
    function computeInflation(uint256 index1, uint256 index2) external view returns (uint256 inflationRate) {
        require(index1 < records.length && index2 < records.length, "Index out of bounds");
        require(index2 > index1, "Second index must be later than first");
        CPIRecord storage record1 = records[index1];
        CPIRecord storage record2 = records[index2];
        // Calculate the rate: ((new / old) - 1) * DECIMALS
        // Here, we compute: (record2.cpi * DECIMALS / record1.cpi) - DECIMALS
        inflationRate = (record2.cpi * DECIMALS / record1.cpi) - DECIMALS;
    }
}
