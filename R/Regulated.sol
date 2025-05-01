// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RegulatedRegistry
 * @notice Defines “Regulated” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RegulatedRegistry {
    /// @notice Types of regulation scopes
    enum RegulatedType {
        KYCRequired,         // Know-Your-Customer checks enforced
        AMLCompliant,        // Anti-Money-Laundering measures enforced
        Securities,          // Subject to securities regulations
        StablecoinPegged,    // Regulation specific to pegged stablecoins
        LicensingRequired    // Requires operator licensing
    }

    /// @notice Attack vectors targeting regulated systems
    enum AttackType {
        Evasion,             // bypassing compliance checks
        DocumentForgery,     // forging identity documents
        RegulatoryArbitrage, // exploiting inconsistent regs across jurisdictions
        PrivacyLeak,         // improper handling of personal data
        InsiderManipulation  // collusion with regulators or insiders
    }

    /// @notice Defense mechanisms for regulatory compliance
    enum DefenseType {
        OnchainKYC,          // on-chain identity verification registry
        MultiJurisdiction,   // adapt to multiple regulatory frameworks
        DataEncryption,      // encrypt sensitive data at rest and transit
        AuditLogging,        // immutable logs for audit trails
        AccessControl        // strict role-based permissions
    }

    struct Term {
        RegulatedType regulatedModel;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed  id,
        RegulatedType    regulatedModel,
        AttackType       attack,
        DefenseType      defense,
        uint256          timestamp
    );

    /**
     * @notice Register a new Regulated term.
     * @param regulatedModel The regulatory model category.
     * @param attack         The anticipated attack vector.
     * @param defense        The chosen defense mechanism.
     * @return id            The ID of the newly registered term.
     */
    function registerTerm(
        RegulatedType regulatedModel,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            regulatedModel: regulatedModel,
            attack:         attack,
            defense:        defense,
            timestamp:      block.timestamp
        });
        emit TermRegistered(id, regulatedModel, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Regulated term.
     * @param id The term ID.
     * @return regulatedModel The regulatory model category.
     * @return attack         The attack vector.
     * @return defense        The defense mechanism.
     * @return timestamp      When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RegulatedType regulatedModel,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.regulatedModel, t.attack, t.defense, t.timestamp);
    }
}
