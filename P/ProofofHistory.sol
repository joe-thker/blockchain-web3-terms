// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfHistoryRegistry
 * @notice Defines “Proof-of-History (PoH)” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ProofOfHistoryRegistry {
    /// @notice Variants of Proof-of-History schemes
    enum PoHType {
        VDFClock,           // Verifiable Delay Function based timekeeping
        SequentialHash,     // chained hashes as a time-ordered record
        SignedTimestamp,    // signatures on timestamps by authority
        MerkleTimeLocks,    // time-locked Merkle proofs
        Hybrid              // combination of multiple PoH techniques
    }

    /// @notice Attack vectors targeting PoH mechanisms
    enum AttackType {
        TimestampSpoof,     // forging or backdating timestamps
        SequenceReordering, // reordering events in the hash chain
        DoS,                // flooding to break VDF / delay proofs
        VDFWeakness,        // exploiting weaknesses in the delay function
        ReplayAttack        // reusing old proofs to appear current
    }

    /// @notice Defense mechanisms for securing PoH systems
    enum DefenseType {
        VDFEnforcement,         // strict enforcement of delay function costs
        Checkpointing,          // periodic consensus checkpoints of state
        OracleAnchoring,        // anchoring proofs to independent time oracles
        MultiPathVerification,  // verify proofs across multiple chains
        AuditTrail              // immutable logs for post‐facto auditing
    }

    struct Term {
        PoHType     pohType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PoHType     pohType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Proof-of-History term.
     * @param pohType  The PoH mechanism variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PoHType     pohType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            pohType:   pohType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, pohType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered PoH term.
     * @param id        The term ID.
     * @return pohType   The PoH mechanism variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PoHType     pohType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.pohType, t.attack, t.defense, t.timestamp);
    }
}
