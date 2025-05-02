// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RegulatoryComplianceRegistry
 * @notice Defines “Regulatory Compliance” domains along with common
 *         attack vectors (risks) and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RegulatoryComplianceRegistry {
    /// @notice Types of regulatory compliance domains
    enum ComplianceType {
        KYCAML,            // Know-Your-Customer & Anti-Money-Laundering
        GDPR,              // EU General Data Protection Regulation
        MiCA,              // Markets in Crypto-Assets Regulation (EU)
        SECRegulated,      // U.S. Securities and Exchange Commission rules
        PCI_DSS            // Payment Card Industry Data Security Standard
    }

    /// @notice Attack vectors targeting compliance processes
    enum AttackType {
        DataBreach,        // unauthorized data exfiltration
        DocumentForgery,   // forging identity or compliance documents
        ProcessCircumvention,// bypassing required checks or controls
        InsiderThreat,     // collusion or misuse by trusted personnel
        RegulatoryArbitrage // exploiting inconsistent rules across regions
    }

    /// @notice Defense mechanisms for ensuring compliance
    enum DefenseType {
        ImmutableAuditLogs, // on-chain immutable record of actions
        MultiPartyVerification, // require multiple independent approvals
        EncryptedDataVaults,   // encrypt sensitive data at rest and in transit
        AutomatedReporting,    // real-time on-chain compliance reporting
        JurisdictionalRouting  // route transactions via compliant regions
    }

    struct Term {
        ComplianceType complianceDomain;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        ComplianceType     complianceDomain,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Regulatory Compliance term.
     * @param complianceDomain  The compliance domain/category.
     * @param attack            The anticipated attack vector.
     * @param defense           The chosen defense mechanism.
     * @return id               The ID of the newly registered term.
     */
    function registerTerm(
        ComplianceType complianceDomain,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            complianceDomain: complianceDomain,
            attack:           attack,
            defense:          defense,
            timestamp:        block.timestamp
        });
        emit TermRegistered(id, complianceDomain, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id  The term ID.
     * @return complianceDomain  The compliance domain.
     * @return attack            The attack vector.
     * @return defense           The defense mechanism.
     * @return timestamp         When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ComplianceType complianceDomain,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.complianceDomain, t.attack, t.defense, t.timestamp);
    }
}
