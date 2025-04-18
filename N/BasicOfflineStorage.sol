// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BasicOfflineStorage
 * @notice Map a unique ID to a single off‑chain URI.
 *         Uploader or owner can update/delete their records.
 */
contract BasicOfflineStorage is Ownable {
    struct Record {
        address uploader;
        string  uri;
        uint256 timestamp;
        bool    exists;
    }

    mapping(bytes32 => Record) private _records;

    event RecordAdded(bytes32 indexed id, address indexed uploader, string uri, uint256 timestamp);
    event RecordUpdated(bytes32 indexed id, string newUri);
    event RecordDeleted(bytes32 indexed id);

    constructor() Ownable(msg.sender) {}

    function addRecord(bytes32 id, string calldata uri) external {
        require(!_records[id].exists, "Record exists");
        _records[id] = Record(msg.sender, uri, block.timestamp, true);
        emit RecordAdded(id, msg.sender, uri, block.timestamp);
    }

    function updateRecord(bytes32 id, string calldata newUri) external {
        Record storage rec = _records[id];
        require(rec.exists, "No such record");
        require(rec.uploader == msg.sender || msg.sender == owner(), "Not authorized");
        rec.uri = newUri;
        emit RecordUpdated(id, newUri);
    }

    function deleteRecord(bytes32 id) external {
        Record storage rec = _records[id];
        require(rec.exists, "No such record");
        require(rec.uploader == msg.sender || msg.sender == owner(), "Not authorized");
        delete _records[id];
        emit RecordDeleted(id);
    }

    function getRecord(bytes32 id)
        external
        view
        returns (address uploader, string memory uri, uint256 timestamp)
    {
        Record storage rec = _records[id];
        require(rec.exists, "No such record");
        return (rec.uploader, rec.uri, rec.timestamp);
    }
}
