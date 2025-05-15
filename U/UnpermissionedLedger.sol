// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title UnpermissionedLedger - Anyone can write to this on-chain ledger
contract UnpermissionedLedger {
    struct Record {
        address writer;
        uint256 timestamp;
        string data;
    }

    Record[] public records;

    event RecordWritten(address indexed writer, uint256 indexed id, string data);

    /// @notice Write data to the public ledger
    function write(string calldata data) external {
        records.push(Record({
            writer: msg.sender,
            timestamp: block.timestamp,
            data: data
        }));

        emit RecordWritten(msg.sender, records.length - 1, data);
    }

    function getRecord(uint256 id) external view returns (Record memory) {
        require(id < records.length, "Out of bounds");
        return records[id];
    }

    function totalRecords() external view returns (uint256) {
        return records.length;
    }
}
