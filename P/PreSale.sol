// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PreSaleRegistry
 * @notice Defines “Pre-Sale” round categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PreSaleRegistry {
    /// @notice Types of pre-sale rounds
    enum PreSaleType {
        Seed,           // earliest round to friends & family
        Private,        // round to selected investors
        Strategic,      // round to strategic partners
        Public,         // open to general public
        Whitelist       // restricted to whitelisted participants
    }

    /// @notice Attack vectors targeting pre-sales
    enum AttackType {
        WhitelistWash,      // sybil accounts to abuse whitelist
        FrontRunning,       // bots buying before others
        Misallocation,      // improper use of raised funds
        InsiderDump,        // insiders dumping tokens immediately
        RegulatoryEvasion   // bypassing securities regulations
    }

    /// @notice Defense mechanisms for pre-sales
    enum DefenseType {
        VestingSchedule,    // lock tokens over time
        KYCVerification,    // require identity checks
        AllocationCap,      // cap per-wallet purchase
        TimeLock,           // delay token distribution
        AuditTransparency   // publish audited sale details
    }

    struct Term {
        PreSaleType saleType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PreSaleType saleType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Pre-Sale term.
     * @param saleType The pre-sale round category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PreSaleType saleType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            saleType:  saleType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, saleType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Pre-Sale term.
     * @param id The term ID.
     * @return saleType  The pre-sale round category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PreSaleType saleType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.saleType, t.attack, t.defense, t.timestamp);
    }
}
