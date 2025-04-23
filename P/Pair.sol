// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PairRegistry
 * @notice Defines “Pair” categories (e.g., trading pairs) along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on‐chain for analysis or governance.
 */
contract PairRegistry {
    /// @notice Types of trading pairs
    enum PairType {
        TokenToken,     // two ERC-20 tokens
        TokenETH,       // token against native ETH (or wrapped ETH)
        StablePair,     // two stablecoins
        LPTokenPair,    // liquidity provider tokens pair
        Custom          // any other custom pairing
    }

    /// @notice Attack vectors targeting pairs/liquidity pools
    enum AttackType {
        Sandwich,          // MEV sandwich attacks around trades
        FrontRunning,      // priority gas auctions to jump orders
        OracleManipulation,// feeding bad prices to on‐chain oracles
        LiquidityDrain,    // draining pool depth via large trades
        MEVExtraction      // general miner/validator extractable value
    }

    /// @notice Defense mechanisms for protecting pairs
    enum DefenseType {
        SlippageLimit,     // enforce max allowed slippage
        TWAP,              // use time‐weighted average pricing
        LiquidityLock,     // lock a portion of liquidity during trades
        OracleRedundancy,  // aggregate multiple price feeds
        MEVProtection      // use MEV‐resistant execution (e.g. private pools)
    }

    struct PairTerm {
        PairType    pairType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => PairTerm) public terms;

    event PairTermRegistered(
        uint256 indexed id,
        PairType    pairType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Pair term.
     * @param pairType The category of the trading pair.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the registered term.
     */
    function registerTerm(
        PairType    pairType,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = PairTerm({
            pairType:  pairType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit PairTermRegistered(id, pairType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Pair term.
     * @param id The term ID.
     * @return pairType The trading pair category.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PairType    pairType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        PairTerm storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.pairType, t.attack, t.defense, t.timestamp);
    }
}
