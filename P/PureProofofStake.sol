// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PureProofOfStakeRegistry
 * @notice Defines “Pure Proof of Stake (PPoS)” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract PureProofOfStakeRegistry {
    /// @notice Variants of Pure Proof of Stake models
    enum PPoSType {
        DirectStaking,       // every staker directly participates in validation
        DelegatedStaking,    // stake delegation to elected validators
        NominatedStaking,    // nominators back a set of validators
        EpochBased,          // stake-weighted selection per epoch
        LiquidStaking        // stake via transferable derivative tokens
    }

    /// @notice Attack vectors targeting PPoS systems
    enum AttackType {
        NothingAtStake,      // signing conflicting forks without penalty
        LongRangeAttack,     // adversary replays an old chain fork
        StakeGrinding,       // biasing validator selection via stake timing
        Collusion,           // validators collude to censor or reorg
        DDoS                 // denial-of-service on validator nodes
    }

    /// @notice Defense mechanisms for securing PPoS
    enum DefenseType {
        Slashing,            // economic penalties for misbehavior
        UnbondingPeriod,     // delayed withdrawals to discourage attacks
        RandomizedSelection, // unbiased validator election
        Checkpointing,       // finality checkpoints to prevent forks
        MultiSigGovernance   // multisig control over validator set updates
    }

    struct Term {
        PPoSType    pposType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PPoSType    pposType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new PPoS term.
     * @param pposType  The PPoS model variant.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        PPoSType    pposType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            pposType:  pposType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, pposType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered PPoS term.
     * @param id The term ID.
     * @return pposType  The PPoS model variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PPoSType    pposType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.pposType, t.attack, t.defense, t.timestamp);
    }
}
