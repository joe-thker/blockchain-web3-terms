// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PseudonymousRegistry
 * @notice Defines “Pseudonymous” identity models along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PseudonymousRegistry {
    /// @notice Types of pseudonymous models
    enum PseudonymousType {
        SingleAddress,       // one address per user
        AddressRotation,     // periodically rotate using new addresses
        StealthAddress,      // use stealth addresses per recipient
        RingSignature,       // group-signature unlinkability
        MixerBased           // use of on-chain mixers (CoinJoin)
    }

    /// @notice Attack vectors targeting pseudonymity
    enum AttackType {
        LinkabilityAttack,    // linking multiple addresses to one user
        DustingAttack,        // sending small amounts to trace flows
        TrafficAnalysis,      // network-level deanonymization
        ClusterAnalysis,      // blockchain graph clustering analysis
        KeyReuseAttack        // reuse of keys across services
    }

    /// @notice Defense mechanisms for preserving pseudonymity
    enum DefenseType {
        AddressRotation,      // use fresh addresses for each interaction
        MixerUse,             // route funds through on-chain mixers
        StealthTransactions,  // use stealth address protocols
        RingSignatures,       // hide signer among a ring of keys
        TorRouting            // obfuscate network origin via Tor
    }

    struct Term {
        PseudonymousType typeModel;
        AttackType       attack;
        DefenseType      defense;
        uint256          timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed       id,
        PseudonymousType      typeModel,
        AttackType            attack,
        DefenseType           defense,
        uint256               timestamp
    );

    /**
     * @notice Register a new pseudonymous term.
     * @param typeModel  The pseudonymity model.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        PseudonymousType typeModel,
        AttackType       attack,
        DefenseType      defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            typeModel: typeModel,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, typeModel, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered pseudonymous term.
     * @param id The term ID.
     * @return typeModel  The pseudonymity model.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PseudonymousType typeModel,
            AttackType       attack,
            DefenseType      defense,
            uint256          timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.typeModel, t.attack, t.defense, t.timestamp);
    }
}
