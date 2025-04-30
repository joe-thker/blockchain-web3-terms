// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RebalancingRegistry
 * @notice Defines “Rebalancing” strategies along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RebalancingRegistry {
    /// @notice Types of rebalancing strategies
    enum RebalanceType {
        TimeBased,       // periodic (e.g., daily, weekly) rebalancing
        ThresholdBased,  // rebalance when allocation drifts beyond threshold
        VolatilityBased, // rebalance based on changes in asset volatility
        SmartRebalance,  // algorithmic, on-chain strategy-driven rebalance
        Continuous       // fractional continuous adjustment to target
    }

    /// @notice Attack vectors targeting rebalancing mechanisms
    enum AttackType {
        FrontRunning,       // MEV bots jump rebalance transactions
        OracleManipulation, // corrupt price feeds before rebalance
        SandwichAttack,     // sandwich trades around rebalance execution
        GasPriceSpam,       // inflate gas to delay rebalance
        LiquidityDrain      // drain pool liquidity before rebalance
    }

    /// @notice Defense mechanisms for secure rebalancing
    enum DefenseType {
        TWAPExecution,        // split rebalance over time to reduce impact
        MultiOracleFeeds,     // aggregate multiple oracles for prices
        SlippageLimits,       // cap allowed price slippage per trade
        CircuitBreakers,      // pause rebalance on abnormal conditions
        PermissionedRebalance // restrict who can trigger rebalance
    }

    struct Term {
        RebalanceType rebalanceType;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed   id,
        RebalanceType     rebalanceType,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new Rebalancing term.
     * @param rebalanceType The rebalancing strategy type.
     * @param attack        The anticipated attack vector.
     * @param defense       The chosen defense mechanism.
     * @return id           The ID of the newly registered term.
     */
    function registerTerm(
        RebalanceType rebalanceType,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            rebalanceType: rebalanceType,
            attack:        attack,
            defense:       defense,
            timestamp:     block.timestamp
        });
        emit TermRegistered(id, rebalanceType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Rebalancing term.
     * @param id The term ID.
     * @return rebalanceType The rebalancing strategy type.
     * @return attack        The attack vector.
     * @return defense       The defense mechanism.
     * @return timestamp     When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RebalanceType rebalanceType,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.rebalanceType, t.attack, t.defense, t.timestamp);
    }
}
