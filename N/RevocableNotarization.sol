// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RevocableNotarization
 * @notice Tracks per‑hash ownership and timestamp, with optional revocation.
 */
contract RevocableNotarization {
    struct Record {
        address owner;
        uint256 timestamp;
        bool active;
    }

    mapping(bytes32 => Record) private _records;

    event Notarized(bytes32 indexed docHash, address indexed owner, uint256 timestamp);
    event Revoked(bytes32 indexed docHash, address indexed owner, uint256 timestamp);

    /**
     * @notice Notarize a document hash.
     * @param docHash The keccak256 hash of the document.
     */
    function notarize(bytes32 docHash) external {
        require(docHash != bytes32(0), "Invalid hash");
        Record storage r = _records[docHash];
        require(!r.active, "Already active");
        r.owner = msg.sender;
        r.timestamp = block.timestamp;
        r.active = true;
        emit Notarized(docHash, msg.sender, block.timestamp);
    }

    /**
     * @notice Revoke your notarization.
     * @param docHash The document hash to revoke.
     */
    function revoke(bytes32 docHash) external {
        Record storage r = _records[docHash];
        require(r.active, "Not active");
        require(r.owner == msg.sender, "Not owner");
        r.active = false;
        emit Revoked(docHash, msg.sender, block.timestamp);
    }

    /**
     * @notice Get the record for a document hash.
     * @param docHash The document hash.
     * @return owner The address that notarized it.
     * @return timestamp The timestamp when notarized.
     * @return active Whether the record is still active.
     */
    function getRecord(bytes32 docHash)
        external
        view
        returns (address owner, uint256 timestamp, bool active)
    {
        Record storage r = _records[docHash];
        return (r.owner, r.timestamp, r.active);
    }
}
