// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OuroborosPraosRegistry
 * @notice Registry for variants of the Ouroboros Praos consensus protocol,
 *         along with common attack vectors and defense mechanisms.
 */
contract OuroborosPraosRegistry {
    /// @notice Variants of Ouroboros Praos
    enum PraosVariant {
        Standard,        // original Praos protocol
        Genesis,         // Praos with Genesis improvements
        BFTEnhanced      // Praos with an added BFT finality gadget
    }

    /// @notice Attack vectors against Praos
    enum AttackType {
        LongRange,       // long‑range fork attack
        NothingAtStake,  // nothing‑at‑stake adversary
        SelfishLeader,   // slot leader withholds blocks
        StakeBleeding,   // draining adversary staking over time
        DenialOfService  // DOS against block production
    }

    /// @notice Defense mechanisms for Praos
    enum DefenseType {
        Checkpointing,   // periodic state checkpoints on‑chain
        HonestMajority,  // reliance on >50% honest stake
        VRFCommitment,   // verifiable randomness for leader selection
        FinalityGadget,  // BFT finality overlay
        Slashing         // penalize misbehavior via stake slashing
    }

    struct Term {
        PraosVariant praos;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PraosVariant praos,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Ouroboros Praos term.
     * @param praos   Variant of the Praos protocol.
     * @param attack  Anticipated attack vector.
     * @param defense Chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PraosVariant praos,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            praos:     praos,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, praos, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve a registered term.
     * @param id The term ID.
     * @return praos     The Praos variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PraosVariant praos,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.praos, t.attack, t.defense, t.timestamp);
    }
}
