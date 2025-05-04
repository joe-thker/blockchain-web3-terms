// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScamcoinRegistry
 * @notice Defines “Scamcoin” token scheme variants along with common
 *         attack vectors enabling them and defense mechanisms to mitigate risk.
 *         Users can register and query these combinations on-chain for analysis or governance.
 */
contract ScamcoinRegistry {
    /// @notice Variants of scam token designs
    enum ScamcoinType {
        RugPullToken,       // liquidity withdrawn by deployer
        Honeypot,           // allow buys but block sells
        ExitScamToken,      // team drains treasury after launch
        FakeAirdrop,        // phantom airdrops that never arrive
        MemePumpDump        // pump-and-dump via social hype
    }

    /// @notice Attack vectors powering scamcoins
    enum AttackType {
        AdminKeyAccess,     // deployer holds privileged mint/burn keys
        MaliciousUpgrade,   // on-chain upgrade that steals funds
        FakeLiquidityLock,  // false proof of locked liquidity
        TokenMinting,       // unlimited minting to dump on users
        SocialEngineering   // hype campaigns to lure investors
    }

    /// @notice Defense mechanisms against scamcoins
    enum DefenseType {
        RenounceOwnership,  // remove all admin keys post-deploy
        VerifiedAudit,      // third-party code audit
        LiquidityLockProof, // on-chain locked LP tokens with timelock
        SupplyCap,          // immutable maximum token supply
        MultiSigGovernance  // require multi-sig for critical actions
    }

    struct Term {
        ScamcoinType scheme;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ScamcoinType   scheme,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new Scamcoin term.
     * @param scheme  The scamcoin design variant.
     * @param attack  The attack vector enabling this scam.
     * @param defense The chosen defense mechanism.
     * @return id     The ID of the newly registered term.
     */
    function registerTerm(
        ScamcoinType scheme,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            scheme:    scheme,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, scheme, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Scamcoin term.
     * @param id The term ID.
     * @return scheme    The scamcoin design variant.
     * @return attack    The enabling attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ScamcoinType scheme,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.scheme, t.attack, t.defense, t.timestamp);
    }
}
