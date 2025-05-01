// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RegensRegistry
 * @notice Defines “Regens” community incentive types along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RegensRegistry {
    /// @notice Types of Regens incentive programs
    enum RegensType {
        CommunityGrant,     // direct grants to ecosystem contributors
        TokenIncentive,     // token rewards for active participation
        StakingRewards,     // yield for staking project tokens
        GovernanceIncentive,// rewards for voting and proposal creation
        LiquidityMining     // rewards for providing liquidity
    }

    /// @notice Attack vectors targeting Regens programs
    enum AttackType {
        SybilFarming,       // fake accounts to claim multiple rewards
        FrontRunning,       // bots capturing incentive txs before others
        Collusion,          // coordinated claims to drain incentives
        OracleManipulation, // feeding wrong participation data
        ExitScam            // sudden withdrawal of incentive pool funds
    }

    /// @notice Defense mechanisms for securing Regens programs
    enum DefenseType {
        IdentityVerification, // KYC or on-chain identity proofs
        RateLimiting,         // cap per-account claim frequency
        ReputationScoring,    // weight rewards by contributor reputation
        MultiOracleFeeds,     // aggregate on-chain indicators for participation
        TimelockedFunds       // lock incentive pool to prevent exit scams
    }

    struct Term {
        RegensType   program;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RegensType   program,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Regens term.
     * @param program  The Regens incentive program type.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        RegensType  program,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            program:   program,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, program, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Regens term.
     * @param id The term ID.
     * @return program   The Regens incentive program type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RegensType   program,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.program, t.attack, t.defense, t.timestamp);
    }
}
