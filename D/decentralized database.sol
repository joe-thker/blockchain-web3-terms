// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DecentralizedDatabase
/// @notice Manages dynamic and secure decentralized data storage.
contract DecentralizedDatabase is Ownable, ReentrancyGuard {

    /// @notice Data record structure
    struct DataRecord {
        uint256 id;
        string dataHash;  // Typically IPFS hash or off-chain storage reference
        string metadata;  // Additional metadata
        address createdBy;
        uint256 timestamp;
        bool exists;
    }

    // Counter for data records
    uint256 private nextRecordId;

    // Mapping ID to DataRecord
    mapping(uint256 => DataRecord) private records;

    // Authorized managers
    mapping(address => bool) public managers;

    // Events
    event RecordAdded(uint256 indexed id, string dataHash, address indexed createdBy);
    event RecordUpdated(uint256 indexed id, string newDataHash);
    event RecordRemoved(uint256 indexed id);
    event ManagerAuthorized(address indexed manager);
    event ManagerRevoked(address indexed manager);

    /// Modifier to restrict function calls to managers or owner
    modifier onlyAuthorized() {
        require(managers[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    constructor() Ownable(msg.sender) {}

    /// @notice Authorize new manager dynamically
    function authorizeManager(address manager) external onlyOwner {
        require(manager != address(0), "Invalid address");
        managers[manager] = true;
        emit ManagerAuthorized(manager);
    }

    /// @notice Revoke manager authorization dynamically
    function revokeManager(address manager) external onlyOwner {
        require(managers[manager], "Manager not authorized");
        managers[manager] = false;
        emit ManagerRevoked(manager);
    }

    /// @notice Add new data record dynamically
    function addRecord(string calldata dataHash, string calldata metadata) external onlyAuthorized nonReentrant returns (uint256) {
        require(bytes(dataHash).length > 0, "Data hash required");

        uint256 recordId = nextRecordId++;
        records[recordId] = DataRecord({
            id: recordId,
            dataHash: dataHash,
            metadata: metadata,
            createdBy: msg.sender,
            timestamp: block.timestamp,
            exists: true
        });

        emit RecordAdded(recordId, dataHash, msg.sender);
        return recordId;
    }

    /// @notice Update existing data record dynamically
    function updateRecord(uint256 recordId, string calldata newDataHash, string calldata newMetadata) external onlyAuthorized nonReentrant {
        require(records[recordId].exists, "Record does not exist");
        require(bytes(newDataHash).length > 0, "Data hash required");

        records[recordId].dataHash = newDataHash;
        records[recordId].metadata = newMetadata;
        records[recordId].timestamp = block.timestamp;

        emit RecordUpdated(recordId, newDataHash);
    }

    /// @notice Remove data record dynamically
    function removeRecord(uint256 recordId) external onlyAuthorized nonReentrant {
        require(records[recordId].exists, "Record does not exist");

        delete records[recordId];
        emit RecordRemoved(recordId);
    }

    /// @notice Retrieve data record by ID
    function getRecord(uint256 recordId) external view returns (DataRecord memory) {
        require(records[recordId].exists, "Record does not exist");
        return records[recordId];
    }

    /// @notice Retrieve total count of data records
    function totalRecords() external view returns (uint256) {
        return nextRecordId;
    }
}
