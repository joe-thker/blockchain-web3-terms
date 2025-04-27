// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PortfolioRegistry
 * @notice Defines “Portfolio” categories along with common attack vectors
 *         and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract PortfolioRegistry {
    /// @notice Types of investment portfolios
    enum PortfolioType {
        Aggressive,     // high-risk, high-reward allocation
        Conservative,   // low-risk, income-preserving allocation
        Balanced,       // mix of growth and income assets
        Income,         // focus on dividend or yield-generating assets
        Thematic        // sector- or theme-specific allocation
    }

    /// @notice Attack vectors targeting portfolio management
    enum AttackType {
        MarketManipulation,   // pump-and-dump or spoofing to distort prices
        FrontRunning,         // MEV / priority gas auctions against rebalances
        OracleManipulation,   // feeding incorrect price oracles for valuation
        InsiderTrading,       // use of privileged information to trade
        LiquidityDrain        // sudden removal of liquidity during rebalances
    }

    /// @notice Defense mechanisms for portfolio protection
    enum DefenseType {
        Diversification,      // spread across many uncorrelated assets
        SlippageControls,     // enforce max slippage on trades
        OracleRedundancy,     // use multiple independent price feeds
        RiskManagement,       // automated checks and circuit breakers
        TimeWeightedRebalance // staggered rebalances to reduce impact
    }

    struct Term {
        PortfolioType portfolio;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PortfolioType portfolio,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Portfolio term.
     * @param portfolio The portfolio category.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        PortfolioType portfolio,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            portfolio: portfolio,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, portfolio, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Portfolio term.
     * @param id The term ID.
     * @return portfolio The portfolio category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PortfolioType portfolio,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.portfolio, t.attack, t.defense, t.timestamp);
    }
}
