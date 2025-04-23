// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OversoldRegistry
 * @notice Defines “Oversold” technical analysis signals along with 
 *         common attack vectors that exploit oversold conditions 
 *         and defense mechanisms to mitigate them. Users can register 
 *         and query these combinations on-chain.
 */
contract OversoldRegistry {
    /// @notice Types of “Oversold” signals
    enum OversoldType {
        RSI,               // Relative Strength Index < threshold
        Stochastic,        // Stochastic Oscillator < threshold
        BollingerBands,    // Price below lower Bollinger Band
        CCI,               // Commodity Channel Index < threshold
        MACDHistogram      // MACD histogram extreme low reading
    }

    /// @notice Attack vectors targeting oversold markets
    enum AttackType {
        DumpAndPump,       // rapid price dump then pump
        Spoofing,          // placing large fake orders downwards
        WashTrading,       // artificial sell volume to push indicators
        OracleManipulation,// feeding incorrect low price data
        BearRaid           // orchestrated sell-off to trigger stops
    }

    /// @notice Defense mechanisms against oversold exploits
    enum DefenseType {
        CircuitBreaker,    // pause trading on extreme drops
        SlippageControl,   // enforce max slippage in sell orders
        OracleRedundancy,  // aggregate multiple price feeds
        LimitOrderOnly,    // restrict to limit orders during dips
        SpreadMonitoring   // widen spreads or alert on anomalies
    }

    struct Term {
        OversoldType oversold;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        OversoldType oversold,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Oversold term.
     * @param oversold The oversold signal type.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        OversoldType oversold,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            oversold:  oversold,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, oversold, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return oversold  The oversold signal type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OversoldType oversold,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.oversold, t.attack, t.defense, t.timestamp);
    }
}
