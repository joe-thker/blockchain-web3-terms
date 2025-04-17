// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DocumentNotarization
 * @notice A simple on‑chain notarization contract.  
 *         Users can submit a document hash to record its timestamp and ownership,
 *         and later verify or revoke their notarizations.
 */
contract DocumentNotarization {
    struct Record {
        address owner;      // Who notarized the document
        uint256 timestamp;  // When it was notarized
        bool exists;        // Whether the record is active
    }

    // Mapping from document hash to its notarization record
    mapping(bytes32 => Record) private _records;

    /// @notice Emitted when a document is notarized
    event Notarized(bytes32 indexed docHash, address indexed owner, uint256 timestamp);

    /// @notice Emitted when a document notarization is revoked
    event Revoked(bytes32 indexed docHash, address indexed owner, uint256 timestamp);

    /**
     * @notice Notarize a document by its hash.
     * @param docHash The keccak256 hash of the document.
     */
    function notarize(bytes32 docHash) external {
        require(docHash != bytes32(0), "Invalid document hash");
        Record storage r = _records[docHash];
        require(!r.exists, "Already notarized");

        r.owner = msg.sender;
        r.timestamp = block.timestamp;
        r.exists = true;

        emit Notarized(docHash, msg.sender, block.timestamp);
    }

    /**
     * @notice Revoke a previously notarized document.
     * @dev Only the original notarizer may revoke.
     * @param docHash The hash of the document to revoke.
     */
    function revoke(bytes32 docHash) external {
        Record storage r = _records[docHash];
        require(r.exists, "Not notarized");
        require(r.owner == msg.sender, "Not owner");

        r.exists = false;
        emit Revoked(docHash, msg.sender, block.timestamp);
    }

    /**
     * @notice Verify a document's notarization status.
     * @param docHash The hash of the document.
     * @return isNotarized True if the document is currently notarized.
     * @return owner The address that notarized (or revoked) it.
     * @return timestamp The original notarization timestamp.
     */
    function verify(bytes32 docHash)
        external
        view
        returns (
            bool isNotarized,
            address owner,
            uint256 timestamp
        )
    {
        Record storage r = _records[docHash];
        return (r.exists, r.owner, r.timestamp);
    }
}
