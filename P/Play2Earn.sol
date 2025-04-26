// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Play2EarnRegistry
 * @notice Defines “Play2Earn” reward models along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract Play2EarnRegistry {
    /// @notice Types of Play2Earn models
    enum Play2EarnType {
        InGameCurrency,    // earn fungible tokens in-game
        AssetOwnership,    // earn NFTs or unique in-game assets
        SkillBasedRewards, // rewards based on player skill/performance
        StakingRewards,    // stake tokens or assets to earn yield
        SocialRewards      // community engagement or social actions
    }

    /// @notice Attack vectors targeting Play2Earn systems
    enum AttackType {
        Cheating,             // exploiting game mechanics to gain unfair rewards
        Botting,              // automated farming of rewards
        ContractExploit,      // smart contract vulnerabilities exploited
        Phishing,             // credential theft to hijack rewards
        Ransomware            // locking user assets/data for ransom
    }

    /// @notice Defense mechanisms for Play2Earn systems
    enum DefenseType {
        AntiCheatSystem,      // on-chain/off-chain cheat detection
        SecurityAudits,       // regular code and economic audits
        RateLimiting,         // throttle excessive reward claims
        SecureOracle,         // trusted randomness/oracle feeds
        MultiFactorAuth       // require additional authentication for key actions
    }

    struct Term {
        Play2EarnType model;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        Play2EarnType model,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Play2Earn term.
     * @param model   The Play2Earn reward model.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        Play2EarnType model,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            model:     model,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, model, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return model     The Play2Earn reward model.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            Play2EarnType model,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.model, t.attack, t.defense, t.timestamp);
    }
}
