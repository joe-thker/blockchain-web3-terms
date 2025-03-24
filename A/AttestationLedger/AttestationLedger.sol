// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title TermsDictionary
/// @notice A contract to store and retrieve various technical, financial, and blockchain-related terms along with their definitions.
contract TermsDictionary {
    // Mapping from a term (string) to its definition (string)
    mapping(string => string) private terms;

    // Event emitted when a term is added or updated.
    event TermAddedOrUpdated(string term, string definition);

    /// @notice Constructor to initialize some common terms.
    constructor() {
        // Initial terms and definitions.
        terms["Blockchain"] = "A decentralized digital ledger that records transactions across multiple computers.";
        terms["Smart Contract"] = "Self-executing code with the terms of the agreement directly written into the blockchain.";
        terms["Attestation Ledger"] = "A system that records verifiable attestations, where trusted parties digitally sign claims or statements about data or identities, ensuring data integrity and trust. Commonly used for identity verification, data integrity, reputation systems, compliance, and decentralized trust frameworks.";

        // Emit events for each term added.
        emit TermAddedOrUpdated("Blockchain", terms["Blockchain"]);
        emit TermAddedOrUpdated("Smart Contract", terms["Smart Contract"]);
        emit TermAddedOrUpdated("Attestation Ledger", terms["Attestation Ledger"]);
    }

    /// @notice Adds or updates a term 
