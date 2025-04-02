// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DigitalSignature
/// @notice A dynamic, optimized smart contract that verifies ECDSA signatures off-chain and stores them on-chain.
/// Users submit a hashed message plus their signature. The contract checks authenticity via ecrecover, then records it.
contract DigitalSignature is ReentrancyGuard {
    /// @notice Data structure to store a verified signature record.
    struct SignatureRecord {
        address signer;        // The address recovered from the signature
        bytes32 messageHash;   // The hashed message that was signed
        uint256 timestamp;     // When the signature was verified and stored
        bool active;           // True if the record is active, false if removed
    }

    /// @notice Mapping from a record ID to its signature details.
    SignatureRecord[] public records;

    // --- Events ---
    event SignatureVerified(
        uint256 indexed recordId,
        address indexed signer,
        bytes32 messageHash,
        uint256 timestamp
    );
    event SignatureRemoved(uint256 indexed recordId, address indexed remover, uint256 timestamp);

    /// @notice Verifies an off-chain ECDSA signature for a given hashed message. If valid, stores a record on-chain.
    /// @param messageHash The Keccak-256 hash of the original message (signed off-chain).
    /// @param v The v component of the signature (27 or 28).
    /// @param r The r component of the signature.
    /// @param s The s component of the signature.
    /// @return recordId The ID of the newly created signature record.
    function verifyAndStore(
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

        // Prepend "\x19Ethereum Signed Message:\n32" if the user used eth_sign or personal_sign?
        // If so, do: bytes32 ethMsgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        // For demonstration, we'll assume the user passed the raw hashed message they actually signed.

        // Recover the signer address from the signature
        address recovered = ecrecover(messageHash, v, r, s);
        require(recovered != address(0), "Invalid signature");

        // Create a new record
        recordId = records.length;
        records.push(SignatureRecord({
            signer: recovered,
            messageHash: messageHash,
            timestamp: block.timestamp,
            active: true
        }));

        emit SignatureVerified(recordId, recovered, messageHash, block.timestamp);
    }

    /// @notice Removes a previously stored signature record. Only the recovered signer (or the record's signer) can remove it.
    /// @param recordId The ID of the signature record to remove.
    function removeSignature(uint256 recordId) external nonReentrant {
        require(recordId < records.length, "Invalid record ID");
        SignatureRecord storage rec = records[recordId];
        require(rec.active, "Record not active");
        require(msg.sender == rec.signer, "Only the signature owner can remove");

        rec.active = false;
        emit SignatureRemoved(recordId, msg.sender, block.timestamp);
    }

    /// @notice Retrieves a specific signature record by ID.
    /// @param recordId The ID of the record to retrieve.
    /// @return A SignatureRecord struct with signer, messageHash, timestamp, and active status.
    function getRecord(uint256 recordId)
        external
        view
        returns (SignatureRecord memory)
    {
        require(recordId < records.length, "Invalid record ID");
        return records[recordId];
    }

    /// @notice Returns the total number of signature records ever created (including removed).
    /// @return The number of records in the records array.
    function totalRecords() external view returns (uint256) {
        return records.length;
    }
}
