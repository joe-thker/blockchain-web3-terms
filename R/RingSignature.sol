// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RingSignatureRegistry
 * @notice Defines “Ring Signature” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RingSignatureRegistry {
    /// @notice Variants of ring signature schemes
    enum RingSignatureType {
        Linkable,          // linkable ring signatures (e.g., Monero)
        Traceable,         // traceable ring signatures with linkability tags
        Threshold,         // threshold ring signatures (M-of-N)
        Aggregate,         // aggregated ring signatures
        ModuleBased        // modular ring signatures using zero-knowledge
    }

    /// @notice Attack vectors against ring signature privacy/integrity
    enum AttackType {
        KeyImageReplay,    // reuse of key images to link transactions
        TraceabilityLeak,  // poor parameter choice leaking member identity
        Collusion,         // colluding ring members to deanonymize signer
        SideChannel,       // leaking through timing or power consumption
        FaultInjection     // corrupting randomness or protocol steps
    }

    /// @notice Defense mechanisms to strengthen ring signature schemes
    enum DefenseType {
        LargeRingSize,     // increase ring size to improve anonymity set
        ImprovedSampling,  // use cryptographically secure decoy sampling
        RandomizedDelay,   // add random delays to signature generation
        HardwareEnclave,   // generate signatures within secure hardware
        AuditableLogs      // log ring formation parameters for audit
    }

    struct Term {
        RingSignatureType scheme;
        AttackType         attack;
        DefenseType        defense;
        uint256            timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed     id,
        RingSignatureType   scheme,
        AttackType          attack,
        DefenseType         defense,
        uint256             timestamp
    );

    /**
     * @notice Register a new Ring Signature term.
     * @param scheme  The ring signature variant.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id     The ID of the newly registered term.
     */
    function registerTerm(
        RingSignatureType scheme,
        AttackType        attack,
        DefenseType       defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            scheme:    scheme,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, scheme, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Ring Signature term.
     * @param id The term ID.
     * @return scheme    The ring signature variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RingSignatureType scheme,
            AttackType        attack,
            DefenseType       defense,
            uint256           timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.scheme, t.attack, t.defense, t.timestamp);
    }
}
