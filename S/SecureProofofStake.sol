// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SPoSRegistry
 * @notice Defines “Secure Proof of Stake (SPoS)” variants along with common
 *         attack vectors and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract SPoSRegistry {
    /// @notice Variants of Secure Proof of Stake designs
    enum SPoSType {
        NominatedProof,       // nominators back validators with stake
        WeightedRandomness,   // leader chosen by weighted VRF
        SlashingEnabled,      // penalize misbehavior with stake slashing
        CommitteeRotation,    // rotating validator committees each epoch
        HybridPoS             // combines PoS with BFT finality rounds
    }

    /// @notice Attack vectors targeting SPoS consensus
    enum AttackType {
        LongRangeAttack,      // create alternative history by using old keys
        NothingAtStake,       // validators sign conflicting blocks
        ValidatorBribery,     // bribing validators to sign illegal blocks
        DenialOfService,      // DDoS attacks on validator nodes
        RandomnessManipulation// biasing VRF outputs for leader selection
    }

    /// @notice Defense mechanisms for securing SPoS
    enum DefenseType {
        FinalityGadget,       // use BFT finality to lock in blocks
        SlashingConditions,   // strict on-chain slashing for double-signing
        MultiVRF,             // aggregate multiple VRFs for unbiased randomness
        RedundantClients,     // run multiple validator clients in parallel
        HonestMajorityProof   // require proof of >50% honest stake for epoch
    }

    struct Term {
        SPoSType    variant;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        SPoSType      variant,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new SPoS term.
     * @param variant  The SPoS design variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        SPoSType    variant,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            variant:   variant,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, variant, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered SPoS term.
     * @param id The term ID.
     * @return variant   The SPoS design variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            SPoSType    variant,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.variant, t.attack, t.defense, t.timestamp);
    }
}
