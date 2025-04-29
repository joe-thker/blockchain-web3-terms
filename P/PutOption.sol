// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PutOptionRegistry
 * @notice Defines “Put Option” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PutOptionRegistry {
    /// @notice Types of put options
    enum PutOptionType {
        European,       // exercisable only at expiration
        American,       // exercisable any time up to expiration
        Bermudan,       // exercisable on specified dates
        Asian,          // payoff depends on average underlying price
        Barrier         // activated or deactivated by barrier trigger
    }

    /// @notice Attack vectors targeting put option positions
    enum AttackType {
        VolatilityManipulation, // artificial volatility spikes
        LiquidityAttack,        // squeezing bid–ask spreads
        PriceManipulation,      // spoofing or wash trading underlying
        CounterpartyDefault,    // issuer fails to honor exercise
        ModelMispricing         // exploit flawed pricing models
    }

    /// @notice Defense mechanisms for put option risk management
    enum DefenseType {
        MarginRequirement,      // enforce collateral on writers
        ClearinghouseGuarantee, // guarantee settlement via CCP
        HedgeStrategy,         // dynamic hedging of underlying exposure
        RegulatoryOversight,    // monitoring by financial authority
        StressTesting           // periodic scenario-based tests
    }

    struct Term {
        PutOptionType optionType;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        PutOptionType      optionType,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Put Option term.
     * @param optionType The put option category.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        PutOptionType optionType,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            optionType: optionType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, optionType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Put Option term.
     * @param id The term ID.
     * @return optionType The put option category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PutOptionType optionType,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.optionType, t.attack, t.defense, t.timestamp);
    }
}
