// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OfflineStorage
 * @notice Allows users to register and manage off‑chain content references (e.g. IPFS hashes).
 *         Each record has a unique ID, uploader, timestamp, and metadata URI.
 */
contract OfflineStorage is Ownable {
    struct Record {
        address uploader;
        string  uri;
        uint256 timestamp;
        bool    exists;
    }

    /// @dev Mapping from record ID to Record data.
    mapping(bytes32 => Record) private _records;

    event RecordAdded(bytes32 indexed id, address indexed uploader, string uri, uint256 timestamp);
    event RecordUpdated(bytes32 indexed id, string newUri);
    event RecordDeleted(bytes32 indexed id);

    /**
     * @dev Pass msg.sender to Ownable so deployer becomes the owner.
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Add a new record.
     * @param id  Unique record identifier (e.g. keccak256 of content).
     * @param uri Off‑chain URI (IPFS hash, Arweave link, etc.).
     */
    function addRecord(bytes32 id, string calldata uri) external {
        require(!_records[id].exists, "OfflineStorage: record already exists");
        _records[id] = Record({
            uploader: msg.sender,
            uri: uri,
            timestamp: block.timestamp,
            exists: true
        });
        emit RecordAdded(id, msg.sender, uri, block.timestamp);
    }

    /**
     * @notice Update an existing record's URI.
     * @param id     Record identifier.
     * @param newUri New URI to associate.
     */
    function updateRecord(bytes32 id, string calldata newUri) external {
        Record storage rec = _records[id];
        require(rec.exists, "OfflineStorage: record does not exist");
        require(rec.uploader == msg.sender || msg.sender == owner(), "OfflineStorage: not authorized");
        rec.uri = newUri;
        emit RecordUpdated(id, newUri);
    }

    /**
     * @notice Delete a record.
     * @param id Record identifier.
     */
    function deleteRecord(bytes32 id) external {
        Record storage rec = _records[id];
        require(rec.exists, "OfflineStorage: record does not exist");
        require(rec.uploader == msg.sender || msg.sender == owner(), "OfflineStorage: not authorized");
        delete _records[id];
        emit RecordDeleted(id);
    }

    /**
     * @notice Retrieve a record's metadata.
     * @param id Record identifier.
     * @return uploader  The address that added the record.
     * @return uri       The off‑chain URI.
     * @return timestamp When the record was added.
     */
    function getRecord(bytes32 id)
        external
        view
        returns (address uploader, string memory uri, uint256 timestamp)
    {
        Record storage rec = _records[id];
        require(rec.exists, "OfflineStorage: record does not exist");
        return (rec.uploader, rec.uri, rec.timestamp);
    }
}
