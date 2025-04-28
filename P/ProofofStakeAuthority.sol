// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfStakeAuthorityRegistry
 * @notice Defines “Proof of Stake Authority” roles along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on‐chain for analysis or governance.
 */
contract ProofOfStakeAuthorityRegistry {
    /// @notice Types of PoS authority roles
    enum AuthorityType {
        ValidatorNode,       // node that proposes/validates blocks
        Delegator,           // staker who delegates to validators
        PoolOperator,        // operator of a staking pool
        GovernanceCouncil,   // governance committee for protocol changes
        SlashingModule       // module enforcing slashing conditions
    }

    /// @notice Attack vectors targeting PoS authorities
    enum AttackType {
        NothingAtStake,      // validators vote on multiple forks
        LongRangeAttack,     // adversary revisits old chain fork
        StakeGrinding,       // biasing block proposer selection
        Collusion,           // validators colluding to censor or fork
        DDoS                 // denial‐of‐service on authority nodes
    }

    /// @notice Defense mechanisms for PoS authorities
    enum DefenseType {
        Checkpointing,       // finality checkpoints to bind history
        SlashingConditions,  // economic penalties for misbehavior
        UnbondingPeriod,     // delayed withdrawal to discourage attacks
        RandomizedSelection, // unbiased proposer election via beacon
        MultiSigGovernance   // multi‐signature for critical actions
    }

    struct Term {
        AuthorityType authority;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed   id,
        AuthorityType     authority,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new PoS Authority term.
     * @param authority The PoS authority role.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        AuthorityType authority,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            authority: authority,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, authority, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered PoS Authority term.
     * @param id The term ID.
     * @return authority The PoS authority role.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            AuthorityType authority,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.authority, t.attack, t.defense, t.timestamp);
    }
}
