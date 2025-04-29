// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PublicSaleRegistry
 * @notice Defines “Public Sale” round categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PublicSaleRegistry {
    /// @notice Types of public sale rounds
    enum PublicSaleType {
        ICO,             // Initial Coin Offering
        IEO,             // Initial Exchange Offering
        IDO,             // Initial DEX Offering
        DutchAuction,    // price descending auction
        Lottery,         // randomized allocation
        BondingCurve     // price set by supply curve
    }

    /// @notice Attack vectors targeting public sales
    enum AttackType {
        WhitelistWash,       // sybil accounts abuse whitelist
        FrontRunning,        // bots buying before others
        PriceManipulation,   // manipulating sale price or state
        Phishing,            // tricking participants into losing funds
        DOS                  // flooding sale contract to block buys
    }

    /// @notice Defense mechanisms for public sale security
    enum DefenseType {
        KYCVerification,     // require identity checks before participation
        AllocationCap,       // per-wallet purchase limit
        RandomSelection,     // lottery/randomized allocation to prevent bots
        TimeLock,            // delay token distribution
        AuditTransparency    // publish audited sale parameters
    }

    struct Term {
        PublicSaleType saleType;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        PublicSaleType     saleType,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Public Sale term.
     * @param saleType The public sale round category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PublicSaleType saleType,
        AttackType     attack,
        DefenseType    defense
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
     * @notice Retrieve details of a registered Public Sale term.
     * @param id The term ID.
     * @return saleType  The public sale round category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PublicSaleType saleType,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.saleType, t.attack, t.defense, t.timestamp);
    }
}
