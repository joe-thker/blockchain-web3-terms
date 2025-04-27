// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PositionSizeRegistry
 * @notice Defines “Position Size” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PositionSizeRegistry {
    /// @notice Types of position sizing methodologies
    enum PositionSizeType {
        Absolute,             // fixed quantity per position
        PercentOfPortfolio,   // defined as a percentage of total equity
        RiskBased,            // scaled to target risk per trade
        VolatilityAdjusted,   // adjusts size based on market volatility
        FixedLotSize          // uses standardized lot increments
    }

    /// @notice Attack vectors targeting position sizing
    enum AttackType {
        Overleveraging,       // taking positions too large relative to collateral
        SlippageAttack,       // causing unexpected price movements upon entry/exit
        FrontRunning,         // MEV attacks to jump ahead of orders
        MarginCallCascade,    // triggering liquidation spirals
        StopHunting           // manipulating price to trigger stop orders
    }

    /// @notice Defense mechanisms for position sizing
    enum DefenseType {
        RiskLimit,            // enforce maximum risk per position
        SlippageControl,      // set tight slippage tolerances on orders
        StopLimitOrders,      // use stop-limit instead of market stops
        CircuitBreaker,       // pause new positions under extreme volatility
        PositionSizingAlgo    // algorithmic sizing based on live metrics
    }

    struct Term {
        PositionSizeType sizeType;
        AttackType       attack;
        DefenseType      defense;
        uint256          timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PositionSizeType sizeType,
        AttackType       attack,
        DefenseType      defense,
        uint256          timestamp
    );

    /**
     * @notice Register a new Position Size term.
     * @param sizeType The position sizing methodology.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PositionSizeType sizeType,
        AttackType       attack,
        DefenseType      defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            sizeType:  sizeType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, sizeType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Position Size term.
     * @param id The term ID.
     * @return sizeType  The position sizing methodology.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PositionSizeType sizeType,
            AttackType       attack,
            DefenseType      defense,
            uint256          timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.sizeType, t.attack, t.defense, t.timestamp);
    }
}
