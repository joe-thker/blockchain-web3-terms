// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OverboughtRegistry
 * @notice Defines “Overbought” technical analysis signals along with 
 *         common attack vectors that exploit overbought conditions 
 *         and defense mechanisms to mitigate them. Users can register 
 *         and query these combinations on-chain.
 */
contract OverboughtRegistry {
    /// @notice Types of “Overbought” signals
    enum OverboughtType {
        RSI,                // Relative Strength Index > threshold
        Stochastic,         // Stochastic Oscillator > threshold
        BollingerBands,     // Price above upper Bollinger Band
        CCI,                // Commodity Channel Index > threshold
        MACDHistogram       // MACD histogram extreme reading
    }

    /// @notice Attack vectors targeting overbought markets
    enum AttackType {
        PumpAndDump,        // rapid price pumping then dumping
        Spoofing,           // placing large fake orders
        WashTrading,        // artificial volume to push indicators
        OracleManipulation, // feeding incorrect price data
        FlashLoanAttack     // using flash loans to spike price
    }

    /// @notice Defense mechanisms against overbought exploits
    enum DefenseType {
        CircuitBreaker,     // pause trading on extreme runs
        SlippageControl,    // enforce max slippage in orders
        OracleRedundancy,   // aggregate multiple price feeds
        LimitOrderOnly,     // restrict to limit orders during peaks
        SpreadMonitoring    // widen spreads or alert on anomalies
    }

    struct Term {
        OverboughtType overbought;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        OverboughtType overbought,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new Overbought term.
     * @param overbought The overbought signal type.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        OverboughtType overbought,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            overbought: overbought,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, overbought, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return overbought The overbought signal type.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OverboughtType overbought,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.overbought, t.attack, t.defense, t.timestamp);
    }
}
