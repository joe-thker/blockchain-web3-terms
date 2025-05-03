// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RugPullRegistry
 * @notice Defines “Rug Pull” scenarios along with common attack vectors and defense mechanisms.
 *         Users can register and query these combinations on-chain for analysis or governance.
 */
contract RugPullRegistry {
    /// @notice Variants of rug pull schemes
    enum RugPullType {
        LiquidityRug,         // dev removes liquidity suddenly
        ExitScam,             // team steals collected funds
        Honeypot,             // contract forbids sells after buys
        FakeTokenListing,     // pump-and-dump via false exchange listings
        GovernanceRug         // malicious governance proposal drains treasury
    }

    /// @notice Attack vectors enabling rug pulls
    enum AttackType {
        AdminKeyAccess,       // privileged key controls token or liquidity
        MaliciousUpgrade,     // contract upgrade to steal funds
        HiddenBackdoor,       // secret code path for dev extraction
        FakeLiquidityLock,    // false promise of locked liquidity
        GovernanceExploit     // exploiting governance to seize funds
    }

    /// @notice Defense mechanisms to mitigate rug pull risk
    enum DefenseType {
        RenounceOwnership,    // remove admin keys after launch
        TimelockUpgrade,      // delay upgrades via time-lock
        VerifiedAudits,       // third-party code audits
        LockedLiquidity,      // on-chain proof of locked LP tokens
        MultiSigGovernance    // require multiple signers for critical ops
    }

    struct Term {
        RugPullType   pullType;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RugPullType   pullType,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Rug Pull term.
     * @param pullType The rug pull scheme variant.
     * @param attack   The anticipated enabling attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        RugPullType pullType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            pullType:  pullType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, pullType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Rug Pull term.
     * @param id The term ID.
     * @return pullType  The rug pull scheme variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RugPullType pullType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.pullType, t.attack, t.defense, t.timestamp);
    }
}
