// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title STORegistry
 * @notice Defines “Security Token Offering” (STO) structures along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract STORegistry {
    /// @notice Variants of Security Token Offerings
    enum STOType {
        PublicSTO,         // open to all investors
        PrivatePlacement,  // offered to accredited/whitelisted investors
        RegulationAPlus,   // SEC “Reg A+” offering
        RegulationD,       // SEC “Rule 506(c)” private offering
        RegulationS        // offshore offering under Reg S
    }

    /// @notice Attack vectors targeting STOs
    enum AttackType {
        WhitelistBypass,     // unapproved participants circumvent checks
        FraudulentDisclosures, // false or misleading offering documents
        AdminKeyCompromise,  // attacker uses issuer’s private keys
        FrontRunning,        // bots preempt subscription transactions
        RegulatoryChange     // sudden law changes invalidating terms
    }

    /// @notice Defense mechanisms for securing STOs
    enum DefenseType {
        KYCAMLVerification,    // enforce on-chain identity & AML checks
        AuditTrail,            // immutable record of all disclosures
        MultiSigControl,       // require multi-sig for fund movements
        TimeLockedSubscriptions, // subscriptions open only in defined windows
        RegulatoryTimelock     // delay sensitive changes pending review
    }

    struct Term {
        STOType    stoVariant;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        STOType      stoVariant,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Security Token Offering term.
     * @param stoVariant The STO structure variant.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        STOType     stoVariant,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            stoVariant: stoVariant,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, stoVariant, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered STO term.
     * @param id The term ID.
     * @return stoVariant The STO structure variant.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            STOType     stoVariant,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.stoVariant, t.attack, t.defense, t.timestamp);
    }
}
