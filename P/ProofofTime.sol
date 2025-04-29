// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfTimeRegistry
 * @notice Defines “Proof-of-Time (PoT)” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ProofOfTimeRegistry {
    /// @notice Variants of Proof-of-Time mechanisms
    enum PoTType {
        TimeLockContract,    // locking tokens for a duration as proof
        VDFProof,            // Verifiable Delay Function based proof
        MerkleTimeLock,      // Merkle‐root with time-locked release
        BeaconChainTime,     // anchored to an external beacon chain’s time
        HybridTimeProof      // combination of VDF and time-lock methods
    }

    /// @notice Attack vectors targeting PoT systems
    enum AttackType {
        TimestampForging,    // backdating or forging time evidence
        DelayManipulation,   // manipulating perceived delay or execution time
        DoS,                 // denial-of-service to break proof generation
        ReplayAttack,        // reusing old valid proofs
        VDFWeakness          // exploiting weaknesses in delay functions
    }

    /// @notice Defense mechanisms for securing PoT
    enum DefenseType {
        VDFCostEnforcement,     // enforce minimum VDF resource cost
        Checkpointing,          // periodic consensus checkpoints
        OracleAnchoring,        // anchor proofs to independent time oracles
        MultiChallengeRounds,   // multiple unpredictable VDF challenges
        RateLimiting            // throttle proof submissions per identity
    }

    struct Term {
        PoTType     potType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PoTType     potType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Proof-of-Time term.
     * @param potType  The PoT mechanism variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PoTType     potType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            potType:   potType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, potType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered PoT term.
     * @param id The term ID.
     * @return potType   The PoT mechanism variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PoTType     potType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.potType, t.attack, t.defense, t.timestamp);
    }
}
