// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RankRegistry
 * @notice Defines “Rank” categories along with common attack vectors
 *         and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract RankRegistry {
    /// @notice Types of ranking systems
    enum RankType {
        Leaderboard,     // ordinal ranking (1st, 2nd, 3rd…)
        Tier,            // categorical tiers (Gold, Silver, Bronze)
        ScoreThreshold,  // ranks based on score thresholds
        ReputationScore, // reputation-based ranking
        StakingPower     // rank by amount staked
    }

    /// @notice Attack vectors targeting ranking systems
    enum AttackType {
        SybilAttack,        // fake identities to climb ranking
        ScoreInflation,     // forging or manipulating scores
        Collusion,          // groups boosting each other’s rank
        SpamSubmission,     // flooding with trivial actions to earn rank
        Bribery             // paying others to boost rank
    }

    /// @notice Defense mechanisms for securing ranking integrity
    enum DefenseType {
        IdentityVerification, // KYC or on-chain identity checks
        RateLimiting,         // cap rate of rank-earning actions
        WeightedScoring,      // weight actions by trustworthiness
        MultiFactorAuth,      // require multiple signals (stake + rep)
        AuditTrail            // immutable logs for off-chain audits
    }

    struct Term {
        RankType    rankType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RankType    rankType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Rank term.
     * @param rankType The ranking system category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        RankType    rankType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            rankType:  rankType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, rankType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Rank term.
     * @param id The term ID.
     * @return rankType  The ranking system category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RankType    rankType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.rankType, t.attack, t.defense, t.timestamp);
    }
}
