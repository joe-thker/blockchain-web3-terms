// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PriceImpactRegistry
 * @notice Defines “Price Impact” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PriceImpactRegistry {
    /// @notice Types of price impact factors
    enum PriceImpactType {
        OrderSize,         // impact from large order relative to book
        LiquidityDepth,    // impact due to shallow market depth
        MarketVolatility,  // impact from rapid price swings
        FeeStructure,      // impact from protocol or taker fees
        Custom             // any other custom impact factor
    }

    /// @notice Attack vectors that exacerbate price impact
    enum AttackType {
        FrontRunning,      // MEV sandwich or priority-gas attacks
        MarketManipulation,// spoofing or wash trades to distort depth
        Spoofing,          // fake order book entries to mislead
        WashTrading,       // self-trading to appear deeper/shallow
        FlashLoanAttack    // flash-loan to temporarily skew liquidity
    }

    /// @notice Defense mechanisms to mitigate price impact
    enum DefenseType {
        SlippageControl,   // enforce maximum slippage tolerances
        TWAP,              // split large trades over time with TWAP
        LiquidityProvision,// incentivize deeper order book liquidity
        CircuitBreaker,    // pause trading on extreme impact events
        RateLimiter        // throttle order submission rates
    }

    struct Term {
        PriceImpactType impactType;
        AttackType      attack;
        DefenseType     defense;
        uint256         timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PriceImpactType impactType,
        AttackType      attack,
        DefenseType     defense,
        uint256         timestamp
    );

    /**
     * @notice Register a new Price Impact term.
     * @param impactType The category of price impact.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        PriceImpactType impactType,
        AttackType      attack,
        DefenseType     defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            impactType: impactType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, impactType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Price Impact term.
     * @param id The term ID.
     * @return impactType The price impact category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PriceImpactType impactType,
            AttackType      attack,
            DefenseType     defense,
            uint256         timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.impactType, t.attack, t.defense, t.timestamp);
    }
}
