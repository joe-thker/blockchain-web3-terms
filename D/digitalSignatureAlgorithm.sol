// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DigitalSignatureAlgorithm
/// @notice A dynamic and optimized contract that verifies off-chain ECDSA signatures on-chain.
/// Once verified, it records a minimal record of the signature. Signers can remove (invalidate) their records.
contract DigitalSignatureAlgorithm is ReentrancyGuard {
    /// @notice Different signature algorithms if you want to extend. For now, we only use ECDSA = 0.
    enum SignatureAlgo { ECDSA, Other }

    /// @notice A record storing data about a verified signature, including the recovered signer, the messageHash, 
    /// the signature algorithm used, and whether the record is active.
    struct SignatureRecord {
        address signer;         // The address recovered from the signature
        bytes32 messageHash;    // The hashed message that was signed
        SignatureAlgo algo;     // Which signature algorithm was used (only ECDSA in this example)
        uint256 timestamp;      // When the record was verified and stored
        bool active;            // True if record is active; false if removed
    }

    // Array of signature records
    SignatureRecord[] public records;

    // --- Events ---
    event SignatureVerified(
        uint256 indexed recordId,
        address indexed signer,
        bytes32 messageHash,
        SignatureAlgo algo,
        uint256 timestamp
    );
    event SignatureRemoved(uint256 indexed recordId, address indexed remover, uint256 timestamp);

    /// @notice Verifies an ECDSA signature for a given hashed message, storing a record if successful.
    /// @param messageHash The Keccak-256 hash of the original message (signed off-chain).
    /// @param v The recovery byte of the signature (27 or 28).
    /// @param r The r component of the signature (32 bytes).
    /// @param s The s component of the signature (32 bytes).
    /// @return recordId The ID of the newly created signature record.
    function verifyAndStoreECDSA(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        nonReentrant
        returns (uint256 recordId)
    {
        require(messageHash != bytes32(0), "Invalid messageHash");

        // Recover the signer address using ecrecover
        address recovered = ecrecover(messageHash, v, r, s);
        require(recovered != address(0), "Invalid ECDSA signature");

        // Create a new record
        recordId = records.length;
        records.push(SignatureRecord({
            signer: recovered,
            messageHash: messageHash,
            algo: SignatureAlgo.ECDSA,
            timestamp: block.timestamp,
            active: true
        }));

        emit SignatureVerified(recordId, recovered, messageHash, SignatureAlgo.ECDSA, block.timestamp);
    }

    /// @notice Removes an existing signature record. Only the record’s signer can remove it.
    /// @param recordId The ID of the signature record to remove.
    function removeSignature(uint256 recordId) external nonReentrant {
        require(recordId < records.length, "Invalid record ID");
        SignatureRecord storage rec = records[recordId];
        require(rec.active, "Record not active");
        require(msg.sender == rec.signer, "Only signer can remove record");

        rec.active = false;
        emit SignatureRemoved(recordId, msg.sender, block.timestamp);
    }

    /// @notice Retrieves the total number of records ever created (including removed).
    /// @return The length of the `records` array.
    function totalRecords() external view returns (uint256) {
        return records.length;
    }

    /// @notice Returns a specific signature record by ID.
    /// @param recordId The ID of the record.
    /// @return A SignatureRecord struct with details about the signature.
    function getRecord(uint256 recordId)
        external
        view
        returns (SignatureRecord memory)
    {
        require(recordId < records.length, "Invalid record ID");
        return records[recordId];
    }
}
