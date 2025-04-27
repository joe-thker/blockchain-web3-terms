// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PreIDORegistry
 * @notice Defines “Pre-IDO” sale categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PreIDORegistry {
    /// @notice Types of Pre-IDO sale rounds
    enum PreIDOType {
        SeedRound,         // early funding for friends & family
        PrivateSale,       // sale to private investors
        StrategicSale,     // sale to strategic partners
        CommunitySale,     // selective community whitelist
        EcosystemSale      // sale to ecosystem participants
    }

    /// @notice Attack vectors targeting Pre-IDO rounds
    enum AttackType {
        InsiderDump,       // insiders immediately selling tokens
        WhitelistWash,     // sybil accounts to abuse whitelist
        FrontRunning,      // bots buying before others
        Misallocation,     // misallocation of sale proceeds
        RegulatoryBreach   // non-compliance with securities laws
    }

    /// @notice Defense mechanisms for Pre-IDO rounds
    enum DefenseType {
        VestingSchedule,   // lock tokens over time
        KYCWhitelist,      // require identity verification
        AllocationCap,     // cap per-wallet purchase
        TimeLock,          // delay token distribution
        AuditTransparency  // publish audited sale details
    }

    struct Term {
        PreIDOType  saleType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PreIDOType  saleType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Pre-IDO term.
     * @param saleType  The Pre-IDO sale category.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        PreIDOType  saleType,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
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
     * @notice Retrieve details of a registered Pre-IDO term.
     * @param id The term ID.
     * @return saleType  The Pre-IDO sale category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PreIDOType  saleType,
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
