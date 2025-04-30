// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantZoneRegistry
 * @notice Defines “Quant Zone (FTX Exchange)” features along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract QuantZoneRegistry {
    /// @notice Types of Quant Zone features
    enum QuantZoneType {
        AutomatedTrading,    // algorithmic trading interface
        Backtesting,         // historical strategy testing
        SignalMarketplace,   // buy/sell quant signals
        PortfolioOptimization, // risk/reward optimization tools
        APIIntegration       // REST/WebSocket API access
    }

    /// @notice Attack vectors targeting Quant Zone features
    enum AttackType {
        APIKeyLeak,          // compromise of user API keys
        FrontRunning,        // MEV bots jumping user orders
        DataPoisoning,       // feeding bad market data into models
        Overleverage,        // excessive leverage causing liquidations
        DDoS                 // denial-of-service on trading endpoints
    }

    /// @notice Defense mechanisms for Quant Zone security
    enum DefenseType {
        RateLimiting,        // throttle API requests per key
        APIKeyRotation,      // enforce periodic key renewals
        DataValidation,      // sanity checks on incoming data feeds
        PositionLimits,      // caps on leverage and order sizes
        MonitoringAlerts     // real-time anomaly detection alerts
    }

    struct Term {
        QuantZoneType feature;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        QuantZoneType      feature,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Quant Zone term.
     * @param feature The Quant Zone feature category.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        QuantZoneType feature,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            feature:   feature,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, feature, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Quant Zone term.
     * @param id The term ID.
     * @return feature   The Quant Zone feature category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            QuantZoneType feature,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.feature, t.attack, t.defense, t.timestamp);
    }
}
