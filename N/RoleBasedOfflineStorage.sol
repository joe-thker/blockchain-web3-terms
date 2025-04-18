// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RoleBasedOfflineStorage
 * @notice Only addresses with EDITOR_ROLE (granted by admin) may add, update, or delete records.
 */
contract RoleBasedOfflineStorage is AccessControl {
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    struct Record {
        address editor;
        string  uri;
        uint256 timestamp;
        bool    exists;
    }

    mapping(bytes32 => Record) private _records;

    event RecordAdded(bytes32 indexed id, address indexed editor, string uri, uint256 timestamp);
    event RecordUpdated(bytes32 indexed id, address indexed editor, string newUri);
    event RecordDeleted(bytes32 indexed id, address indexed editor);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(EDITOR_ROLE, admin);
    }

    modifier onlyEditor() {
        require(hasRole(EDITOR_ROLE, msg.sender), "Not an editor");
        _;
    }

    function grantEditor(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(EDITOR_ROLE, account);
    }

    function revokeEditor(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(EDITOR_ROLE, account);
    }

    function addRecord(bytes32 id, string calldata uri) external onlyEditor {
        require(!_records[id].exists, "Record exists");
        _records[id] = Record(msg.sender, uri, block.timestamp, true);
        emit RecordAdded(id, msg.sender, uri, block.timestamp);
    }

    function updateRecord(bytes32 id, string calldata newUri) external onlyEditor {
        Record storage rec = _records[id];
        require(rec.exists, "No such record");
        rec.uri = newUri;
        rec.editor = msg.sender;
        rec.timestamp = block.timestamp;
        emit RecordUpdated(id, msg.sender, newUri);
    }

    function deleteRecord(bytes32 id) external onlyEditor {
        require(_records[id].exists, "No such record");
        delete _records[id];
        emit RecordDeleted(id, msg.sender);
    }

    function getRecord(bytes32 id)
        external
        view
        returns (address editor, string memory uri, uint256 timestamp)
    {
        Record storage rec = _records[id];
        require(rec.exists, "No such record");
        return (rec.editor, rec.uri, rec.timestamp);
    }
}
