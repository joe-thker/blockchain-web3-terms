// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OptionRegistry
 * @notice Defines financial Option types along with potential
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on‑chain for analysis or governance.
 */
contract OptionRegistry {
    /// @notice Types of financial options
    enum OptionType {
        Call,        // right to buy
        Put,         // right to sell
        American,    // exercisable anytime before expiry
        European,    // exercisable only at expiry
        Exotic       // any non‑standard option
    }

    /// @notice Attack vectors that target option positions
    enum AttackType {
        VolatilityManipulation,  // artificially moving implied vol
        PriceOracleSpoof,        // feeding wrong underlying price
        CounterpartyDefault,     // issuer fails to pay
        MarginCallCascade,       // forced liquidations in cascades
        GammaSqueeze             // market makers forced to buy underlying
    }

    /// @notice Defense mechanisms against option attacks
    enum DefenseType {
        CollateralRequirement,   // require over‑collateralization
        HedgingStrategy,         // delta or vega hedging
        MarginRequirements,      // maintenance margins to avoid cascade
        CircuitBreaker,          // pause trading on extreme moves
        OracleRedundancy         // multiple price oracles for consensus
    }

    struct OptionTerm {
        OptionType   optionType;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => OptionTerm) public terms;

    event OptionTermRegistered(
        uint256 indexed id,
        OptionType   optionType,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Option term with its attack and defense.
     * @param optionType The category of the option.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the registered term.
     */
    function registerTerm(
        OptionType   optionType,
        AttackType   attack,
        DefenseType  defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = OptionTerm({
            optionType:  optionType,
            attack:      attack,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit OptionTermRegistered(id, optionType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Option term.
     * @param id The term ID.
     * @return optionType The option category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OptionType   optionType,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        OptionTerm storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.optionType, t.attack, t.defense, t.timestamp);
    }
}
