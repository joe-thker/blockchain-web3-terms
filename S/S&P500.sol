// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SP500Registry
 * @notice Defines “S&P 500” instrument variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract SP500Registry {
    /// @notice Variants of S&P 500 instruments
    enum SPType {
        IndexFund,           // traditional mutual fund tracking S&P 500
        ETF,                 // exchange-traded fund (e.g., SPY)
        FuturesContract,     // CME-listed S&P 500 futures
        TokenizedIndex,      // ERC20 token pegged to S&P 500
        OptionsContract      // options on S&P 500 index
    }

    /// @notice Attack vectors targeting S&P 500 instruments
    enum AttackType {
        OracleManipulation,  // corrupt price feeds used for indexing
        FrontRunning,        // MEV bots jumping trades around rebalance
        DataLatency,         // stale data causing mispricing
        SlippageAttack,      // high slippage during large trades
        FlashLoanArbitrage   // using flash loans to exploit price moves
    }

    /// @notice Defense mechanisms for securing S&P 500 instruments
    enum DefenseType {
        MultiOracleFeeds,    // aggregate multiple price oracles
        TWAPExecution,       // spread large trades over time
        CircuitBreakers,     // pause trading under extreme moves
        SlippageLimits,      // cap acceptable slippage per trade
        CollateralBuffers    // maintain extra reserves to absorb shocks
    }

    struct Term {
        SPType      instrument;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        SPType        instrument,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new S&P 500 term.
     * @param instrument The S&P 500 instrument variant.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        SPType      instrument,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            instrument: instrument,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, instrument, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered S&P 500 term.
     * @param id The term ID.
     * @return instrument The instrument variant.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            SPType      instrument,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.instrument, t.attack, t.defense, t.timestamp);
    }
}
