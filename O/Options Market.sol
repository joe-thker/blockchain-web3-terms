// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OptionsMarketRegistry
 * @notice Defines “Options Market” types along with common attack vectors
 *         and defense mechanisms. Users can register and query
 *         these combinations on‑chain for analysis or governance.
 */
contract OptionsMarketRegistry {
    /// @notice Types of options market structures
    enum MarketType {
        AMM,        // Automated Market Maker (e.g. Lyra, Hegic)
        CEX,        // Centralized Exchange
        DEX,        // Decentralized Exchange orderbook (e.g. dYdX)
        OTC,        // Over‑the‑Counter desks
        Hybrid      // Combination of on‑chain & off‑chain
    }

    /// @notice Attack vectors that target options markets
    enum AttackType {
        FrontRunning,        // MEV / sandwich attacks
        OracleManipulation,  // feeding wrong price data
        LiquidityDrain,      // draining pool liquidity via large trades
        FlashLoanAttack,     // using flash loans to manipulate prices
        CollateralTheft      // exploiting improper settlement
    }

    /// @notice Defense mechanisms employed by options markets
    enum DefenseType {
        CircuitBreaker,      // pause trading on extreme conditions
        MultiOracle,         // use several oracles for price feeds
        SlippageLimit,       // restrict max slippage per trade
        TimeLock,            // delay settlement for manual review
        Whitelist            // restrict participants to approved addresses
    }

    struct MarketTerm {
        MarketType  market;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => MarketTerm) public terms;

    event MarketTermRegistered(
        uint256 indexed id,
        MarketType  market,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Options Market term.
     * @param market  The market structure type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the registered term.
     */
    function registerTerm(
        MarketType  market,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = MarketTerm({
            market:    market,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit MarketTermRegistered(id, market, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Options Market term.
     * @param id The term ID.
     * @return market   The market structure type.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            MarketType  market,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        MarketTerm storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.market, t.attack, t.defense, t.timestamp);
    }
}
