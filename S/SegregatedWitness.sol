// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SegWitRegistry
 * @notice Defines “Segregated Witness (SegWit)” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract SegWitRegistry {
    /// @notice Variants of SegWit deployment
    enum SegWitType {
        Native,           // bech32 P2WPKH/P2WSH addresses
        NestedP2SH,       // P2SH-wrapped witness outputs
        Taproot,          // SegWit v1 (Taproot) v1+ features
        VersionBits,      // future version activation via BIP9
        LightningCompat   // SegWit for Lightning Network compatibility
    }

    /// @notice Attack vectors targeting SegWit
    enum AttackType {
        MalleabilityResidual, // leftover malleability on nested P2SH
        SoftForkDelay,        // slow activation of new versions
        ScriptValidationBug,  // witness script validation errors
        ReplayAcrossForks,    // replaying SegWit tx on legacy chain
        FeeCalculationEdge    // incorrect fee due to weight miscalc
    }

    /// @notice Defense mechanisms for SegWit security
    enum DefenseType {
        WitnessVerification,  // strict witness stack checks
        VersionEnforcement,   // enforce correct version bits rules
        ReplayProtection,     // chain ID or nVersion checks
        WeightCalcAudit,      // audit weight-based fee logic
        UpgradeCoordination   // coordinated activation signaling
    }

    struct Term {
        SegWitType typeVariant;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        SegWitType    typeVariant,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new SegWit term.
     * @param typeVariant The SegWit variant.
     * @param attack      The anticipated attack vector.
     * @param defense     The chosen defense mechanism.
     * @return id         The ID of the newly registered term.
     */
    function registerTerm(
        SegWitType typeVariant,
        AttackType attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            typeVariant: typeVariant,
            attack:      attack,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit TermRegistered(id, typeVariant, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered SegWit term.
     * @param id The term ID.
     * @return typeVariant The SegWit variant.
     * @return attack      The attack vector.
     * @return defense     The defense mechanism.
     * @return timestamp   When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            SegWitType typeVariant,
            AttackType attack,
            DefenseType defense,
            uint256    timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.typeVariant, t.attack, t.defense, t.timestamp);
    }
}
