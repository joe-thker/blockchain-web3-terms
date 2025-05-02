// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RingCTRegistry
 * @notice Defines “Ring CT” (Ring Confidential Transactions) variants along with common
 *         attack vectors and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract RingCTRegistry {
    /// @notice Variants of Ring CT implementations
    enum RingCTType {
        RingCTv1,        // original Monero RingCT
        MLSAG,           // Multilayered Linkable Spontaneous Anonymous Group
        Bulletproofs,    // shorter range proofs
        BulletproofPlus, // faster verification variant
        ConfidentialAssets // RingCT extended to asset type hiding
    }

    /// @notice Attack vectors targeting Ring CT privacy
    enum AttackType {
        Traceability,      // linking inputs across transactions
        KeyImageReuse,     // reuse of key images to trace spends
        DecoySelection,    // poor decoy choice reducing anonymity
        TimingAnalysis,    // correlating tx times to deanonymize
        SideChannel        // hardware/software leaks of secret data
    }

    /// @notice Defense mechanisms for Ring CT privacy
    enum DefenseType {
        LargeRingSize,     // increase number of decoys per input
        AdaptiveDecoys,    // use heuristics to select better decoys
        RangeProofs,       // enforce amount confidentiality via proofs
        BulletproofsPlus,  // use the improved proof variant
        PeerMixing         // batch/reorder txs to obfuscate timing
    }

    struct Term {
        RingCTType ringType;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RingCTType    ringType,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Ring CT term.
     * @param ringType The Ring CT variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        RingCTType ringType,
        AttackType attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            ringType:  ringType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, ringType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Ring CT term.
     * @param id The term ID.
     * @return ringType  The Ring CT variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RingCTType ringType,
            AttackType attack,
            DefenseType defense,
            uint256    timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.ringType, t.attack, t.defense, t.timestamp);
    }
}
