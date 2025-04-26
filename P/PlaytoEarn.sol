// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PlayToEarnRegistry
 * @notice Defines “Play-to-Earn” reward models along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on‐chain for analysis or governance.
 */
contract PlayToEarnRegistry {
    /// @notice Types of Play-to-Earn models
    enum P2EType {
        InGameCurrency,    // earn fungible tokens in-game
        AssetOwnership,    // earn NFTs or unique assets
        SkillBasedRewards, // rewards based on player skill
        StakingRewards,    // stake tokens to earn rewards
        SocialRewards      // community and social engagement
    }

    /// @notice Attack vectors targeting P2E systems
    enum AttackType {
        Cheating,             // exploiting game mechanics
        Botting,              // automated play to farm rewards
        SmartContractExploit, // exploiting contract bugs
        Phishing,             // stealing credentials or private keys
        Ransomware            // locking user assets or data
    }

    /// @notice Defense mechanisms for P2E systems
    enum DefenseType {
        AntiCheatSystem,      // on-chain/off-chain cheat detection
        CodeAudits,           // smart contract security reviews
        RateLimiting,         // throttle excessive reward claims
        RandomnessOracle,     // secure RNG for reward distribution
        MultiFactorAuth       // require additional auth for key actions
    }

    struct Term {
        P2EType     p2eModel;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        P2EType     p2eModel,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Play-to-Earn term.
     * @param p2eModel The P2E reward model.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        P2EType     p2eModel,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            p2eModel:  p2eModel,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, p2eModel, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered P2E term.
     * @param id The term ID.
     * @return p2eModel  The P2E reward model.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            P2EType     p2eModel,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.p2eModel, t.attack, t.defense, t.timestamp);
    }
}
