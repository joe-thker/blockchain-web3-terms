// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReverseIndicatorRegistry
 * @notice Defines “Reverse Indicator” variants along with common
 *         attack vectors (false signals) and defense mechanisms.
 *         Users can register and query these combinations on-chain for analysis or governance.
 */
contract ReverseIndicatorRegistry {
    /// @notice Variants of reverse/trend-flip indicators
    enum IndicatorType {
        MovingAverageCrossover, // price crosses moving average in reverse direction
        RSIFlip,                // RSI moves from overbought to oversold or vice versa
        MACDHistogramFlip,      // MACD histogram changes sign
        BollingerReversion,     // price reverts to Bollinger band mean
        VolumeSpikeReversal     // sudden volume spike signaling trend reversal
    }

    /// @notice Attack vectors causing false indicator signals
    enum AttackType {
        FakeVolume,            // wash trading to create deceptive volume spikes
        OracleManipulation,    // feeding incorrect price data to on-chain oracles
        Spoofing,              // placing and canceling orders to distort moving averages
        Overfitting,           // tailoring indicator parameters to historical anomalies
        LatencyArbitrage       // exploiting delays in data feeds for false flips
    }

    /// @notice Defense mechanisms to mitigate false signals
    enum DefenseType {
        MultiIndicatorCheck,   // require confirmation from multiple indicators
        VolumeThresholds,      // ignore signals below a volume threshold
        OracleRedundancy,      // use aggregated feeds from multiple oracles
        TimeWeightedFilter,    // smooth signals over a minimum time window
        AdaptiveParameters     // dynamically adjust indicator parameters on volatility
    }

    struct Term {
        IndicatorType indicator;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed  id,
        IndicatorType    indicator,
        AttackType       attack,
        DefenseType      defense,
        uint256          timestamp
    );

    /**
     * @notice Register a new Reverse Indicator term.
     * @param indicator The indicator variant.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        IndicatorType indicator,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            indicator: indicator,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, indicator, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return indicator  The indicator variant.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            IndicatorType indicator,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.indicator, t.attack, t.defense, t.timestamp);
    }
}
