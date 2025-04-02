// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DigitalIdentity
/// @notice A dynamic and optimized registry allowing addresses to create, update, and remove their own identities.
/// Each identity contains a name and metadata URI, stored in a minimal on-chain struct.
contract DigitalIdentity is ReentrancyGuard {
    /// @notice Each user's identity record.
    struct Identity {
        bool active;          // Whether the identity is active
        string name;          // A display name or handle
        string metadataURI;   // URI pointing to metadata (JSON, IPFS link, etc.)
        uint256 lastUpdated;  // Timestamp of the last update
    }

    /// @notice Mapping from user address to their identity record.
    mapping(address => Identity) public identities;

    // --- Events ---
    event IdentityCreated(address indexed user, string name, string metadataURI, uint256 timestamp);
    event IdentityUpdated(address indexed user, string newName, string newMetadataURI, uint256 timestamp);
    event IdentityRemoved(address indexed user, uint256 timestamp);

    /// @notice Creates a new identity for the caller's address.
    /// Reverts if the caller already has an active identity.
    /// @param name The name or handle for this identity.
    /// @param metadataURI A URI containing additional info or metadata for this identity.
    function createIdentity(string calldata name, string calldata metadataURI)
        external
        nonReentrant
    {
        require(!identities[msg.sender].active, "Identity already exists");
        require(bytes(name).length > 0, "Name cannot be empty");

        identities[msg.sender] = Identity({
            active: true,
            name: name,
            metadataURI: metadataURI,
            lastUpdated: block.timestamp
        });

        emit IdentityCreated(msg.sender, name, metadataURI, block.timestamp);
    }

    /// @notice Updates an existing identity's name or metadata URI.
    /// Reverts if the caller does not have an active identity.
    /// @param newName The updated name.
    /// @param newMetadataURI The updated metadata URI.
    function updateIdentity(string calldata newName, string calldata newMetadataURI)
        external
        nonReentrant
    {
        Identity storage idRecord = identities[msg.sender];
        require(idRecord.active, "No active identity to update");
        require(bytes(newName).length > 0, "Name cannot be empty");

        idRecord.name = newName;
        idRecord.metadataURI = newMetadataURI;
        idRecord.lastUpdated = block.timestamp;

        emit IdentityUpdated(msg.sender, newName, newMetadataURI, block.timestamp);
    }

    /// @notice Removes (deactivates) the caller's identity record.
    /// Existing data is cleared, but stored as inactive in the mapping.
    function removeIdentity() external nonReentrant {
        Identity storage idRecord = identities[msg.sender];
        require(idRecord.active, "No active identity to remove");

        idRecord.active = false;
        // Optionally clear other fields if desired:
        // idRecord.name = "";
        // idRecord.metadataURI = "";
        idRecord.lastUpdated = block.timestamp;

        emit IdentityRemoved(msg.sender, block.timestamp);
    }

    /// @notice Retrieves the full identity record for a given user.
    /// @param user The address of the user whose identity is requested.
    /// @return A struct with the user's identity data.
    function getUserIdentity(address user)
        external
        view
        returns (Identity memory)
    {
        return identities[user];
    }

    /// @notice Checks if a given user has an active identity.
    /// @param user The address to check.
    /// @return True if the user has an active identity, false otherwise.
    function isActiveIdentity(address user) external view returns (bool) {
        return identities[user].active;
    }
}
