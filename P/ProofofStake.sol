// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfStakeRegistry
 * @notice Defines “Proof-of-Stake (PoS)” variants along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ProofOfStakeRegistry {
    /// @notice Variants of Proof-of-Stake consensus mechanisms
    enum PoSType {
        PurePoS,               // every staker directly participates in consensus
        DelegatedPoS,          // token holders delegate stake to validators
        NominatedPoS,          // nominators back validators with stake
        LeasedPoS,             // lease stake to validators temporarily
        HybridPoS              // mixed PoS with additional consensus layers
    }

    /// @notice Attack vectors targeting PoS networks
    enum AttackType {
        NothingAtStake,        // validators sign conflicting blocks
        LongRangeAttack,       // adversary replays an old fork
        StakeGrinding,         // biasing validator selection by grinding stake
        Collusion,             // validators collude to censor or fork
        DDoS                   // denial‐of‐service on validator nodes
    }

    /// @notice Defense mechanisms for securing PoS
    enum DefenseType {
        Slashing,              // penalize misbehaving validators
        UnbondingPeriod,       // delay withdrawal to discourage attacks
        RandomizedSelection,   // unbiased validator election
        Checkpointing,         // finality checkpoints to prevent forks
        MultiSigGovernance     // multi-signature control over validator set
    }

    struct Term {
        PoSType      posType;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PoSType      posType,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Proof-of-Stake term.
     * @param posType  The PoS variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PoSType      posType,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            posType:    posType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, posType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered PoS term.
     * @param id The term ID.
     * @return posType   The PoS variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PoSType      posType,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.posType, t.attack, t.defense, t.timestamp);
    }
}
