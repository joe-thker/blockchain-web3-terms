// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ESignature
/// @notice This contract enables users to register and revoke e-signatures on-chain.
/// A user submits a message hash along with its signature components (v, r, s).
/// The contract uses ECDSA via ecrecover to verify the signature and records the signature data.
contract ESignature is ReentrancyGuard {
    /// @notice Structure representing a signature record.
    struct SignatureRecord {
        address signer;      // The address recovered from the signature
        bytes32 messageHash; // The hashed message that was signed
        uint256 timestamp;   // Timestamp when the signature was registered
        bool active;         // Whether this signature record is active
    }

    // Array storing all signature records.
    SignatureRecord[] public signatures;

    /// @notice Emitted when a signature is successfully registered.
    /// @param signatureId The ID assigned to the signature record.
    /// @param signer The address that signed the message.
    /// @param messageHash The hash of the signed message.
    /// @param timestamp The time when the signature was registered.
    event SignatureRegistered(
        uint256 indexed signatureId,
        address indexed signer,
        bytes32 messageHash,
        uint256 timestamp
    );

    /// @notice Emitted when a signature is revoked.
    /// @param signatureId The ID of the revoked signature record.
    /// @param signer The address that revoked the signature.
    /// @param timestamp The time when the signature was revoked.
    event SignatureRevoked(
        uint256 indexed signatureId,
        address indexed signer,
        uint256 timestamp
    );

    /// @notice Registers an e-signature record.
    /// @dev The user must provide a message hash along with valid ECDSA signature components (v, r, s).
    ///      The function uses ecrecover to verify that the signature matches the sender.
    /// @param messageHash The hash of the message that was signed.
    /// @param v The recovery identifier.
    /// @param r The r component of the signature.
    /// @param s The s component of the signature.
    /// @return signatureId The ID assigned to the new signature record.
    function registerSignature(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant returns (uint256 signatureId) {
        require(messageHash != bytes32(0), "Invalid message hash");

        // Recover the signer address using ecrecover.
        address recovered = ecrecover(messageHash, v, r, s);
        require(recovered != address(0), "Invalid signature");
        require(recovered == msg.sender, "Signature does not match sender");

        signatureId = signatures.length;
        signatures.push(SignatureRecord({
            signer: msg.sender,
            messageHash: messageHash,
            timestamp: block.timestamp,
            active: true
        }));

        emit SignatureRegistered(signatureId, msg.sender, messageHash, block.timestamp);
    }

    /// @notice Revokes (deactivates) an existing signature record.
    /// @dev Only the original signer can revoke their signature.
    /// @param signatureId The ID of the signature record to revoke.
    function revokeSignature(uint256 signatureId) external nonReentrant {
        require(signatureId < signatures.length, "Invalid signature ID");
        SignatureRecord storage record = signatures[signatureId];
        require(record.active, "Signature already revoked");
        require(msg.sender == record.signer, "Only signer can revoke");

        record.active = false;
        emit SignatureRevoked(signatureId, msg.sender, block.timestamp);
    }

    /// @notice Retrieves a signature record by its ID.
    /// @param signatureId The ID of the signature record.
    /// @return record A SignatureRecord struct containing the signature details.
    function getSignature(uint256 signatureId) external view returns (SignatureRecord memory record) {
        require(signatureId < signatures.length, "Invalid signature ID");
        return signatures[signatureId];
    }

    /// @notice Returns the total number of signature records created.
    /// @return The number of records stored.
    function totalSignatures() external view returns (uint256) {
        return signatures.length;
    }
}
