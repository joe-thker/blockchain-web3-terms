// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PredictionMarketRegistry
 * @notice Defines “Prediction Market” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PredictionMarketRegistry {
    /// @notice Types of prediction markets
    enum MarketType {
        Binary,            // yes/no outcome markets
        Categorical,       // multiple distinct outcomes
        Scalar,            // numeric range outcomes
        Continuous,        // continuous outcome markets
        Custom             // any other specialized market
    }

    /// @notice Attack vectors targeting prediction markets
    enum AttackType {
        FrontRunning,        // MEV sandwich around settling transactions
        OracleManipulation,  // feeding wrong outcome data
        Sybil,               // fake identities to influence consensus
        WashTrading,         // artificially boosting volumes
        Censorship           // blocking resolution or payouts
    }

    /// @notice Defense mechanisms for prediction markets
    enum DefenseType {
        DisputeWindow,       // allow challenges before final settlement
        OracleRedundancy,    // aggregate multiple oracle sources
        TimeWeightedAvg,     // use TWAP for outcome resolution
        BondSlashing,        // penalize dishonest reporters
        CircuitBreaker       // pause resolution under suspicious activity
    }

    struct Term {
        MarketType market;
        AttackType attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        MarketType market,
        AttackType attack,
        DefenseType defense,
        uint256 timestamp
    );

    /**
     * @notice Register a new Prediction Market term.
     * @param market  The prediction market category.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        MarketType  market,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            market:    market,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, market, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Prediction Market term.
     * @param id The term ID.
     * @return market   The prediction market category.
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
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.market, t.attack, t.defense, t.timestamp);
    }
}
