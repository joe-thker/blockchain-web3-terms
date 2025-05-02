// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RelativeStrengthIndexRegistry
 * @notice Defines “Relative Strength Index (RSI)” configurations along with common
 *         attack vectors (risks) and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RelativeStrengthIndexRegistry {
    /// @notice Variants of RSI configurations
    enum RSIType {
        Standard14,       // default 14-period RSI
        ShortTerm,        // 5-period or 7-period RSI
        LongTerm,         // 21-period or higher RSI
        WilderSmoothing,  // original Wilder’s smoothing algorithm
        EMAWeighted       // RSI using exponential moving average
    }

    /// @notice Attack vectors targeting RSI-based strategies
    enum AttackType {
        OracleManipulation,  // feeding false price data into RSI calculation
        FlashPriceSpikes,    // sudden spikes to trigger false overbought/oversold
        SandwichAttack,      // front- and back-running RSI updates
        Overfitting,         // tailoring signals to historical noise
        VolumeWash           // wash trades to distort gain/loss averages
    }

    /// @notice Defense mechanisms for RSI robustness
    enum DefenseType {
        MultiOracleFeeds,    // aggregate multiple price sources
        VolumeFilter,        // filter RSI triggers by minimum volume
        TimeWeightedRSI,     // smooth RSI over time intervals
        ThresholdBuffer,     // use buffers around overbought/oversold levels
        MultiIndicatorCheck  // confirm with another indicator (e.g., MACD)
    }

    struct Term {
        RSIType      rsiConfig;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RSIType      rsiConfig,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new RSI term.
     * @param rsiConfig The RSI configuration variant.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        RSIType     rsiConfig,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            rsiConfig: rsiConfig,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, rsiConfig, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered RSI term.
     * @param id The term ID.
     * @return rsiConfig The RSI configuration variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RSIType     rsiConfig,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.rsiConfig, t.attack, t.defense, t.timestamp);
    }
}
