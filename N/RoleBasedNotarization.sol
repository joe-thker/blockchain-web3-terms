// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RoleBasedNotarization
 * @notice Only authorized notaries can add or revoke notarizations.
 *         Uses OpenZeppelin AccessControl for permissioning.
 */
contract RoleBasedNotarization is AccessControl {
    bytes32 public constant NOTARIZER_ROLE = keccak256("NOTARIZER_ROLE");

    struct Record {
        address owner;
        uint256 timestamp;
        bool active;
    }

    mapping(bytes32 => Record) private _records;

    event Notarized(bytes32 indexed docHash, address indexed notary, uint256 timestamp);
    event Revoked(bytes32 indexed docHash, address indexed notary, uint256 timestamp);

    /**
     * @dev Grant DEFAULT_ADMIN_ROLE and NOTARIZER_ROLE to `admin` on deployment.
     * @param admin The address to receive admin and notary roles.
     */
    constructor(address admin) {
        // Use internal _grantRole (bypasses access check) to bootstrap roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(NOTARIZER_ROLE, admin);
    }

    /**
     * @notice Authorize a new notary.
     * @param account The address to grant NOTARIZER_ROLE.
     */
    function addNotary(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(NOTARIZER_ROLE, account);
    }

    /**
     * @notice Revoke notary rights.
     * @param account The address to revoke NOTARIZER_ROLE.
     */
    function removeNotary(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(NOTARIZER_ROLE, account);
    }

    /**
     * @notice Notarize a document hash.
     * @param docHash The keccak256 hash of the document.
     */
    function notarize(bytes32 docHash) external onlyRole(NOTARIZER_ROLE) {
        require(docHash != bytes32(0), "Invalid hash");
        Record storage r = _records[docHash];
        require(!r.active, "Already active");

        r.owner = msg.sender;
        r.timestamp = block.timestamp;
        r.active = true;

        emit Notarized(docHash, msg.sender, block.timestamp);
    }

    /**
     * @notice Revoke a notarization.
     * @param docHash The document hash to revoke.
     */
    function revoke(bytes32 docHash) external onlyRole(NOTARIZER_ROLE) {
        Record storage r = _records[docHash];
        require(r.active, "Not active");

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
