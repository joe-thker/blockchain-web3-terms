// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RehypothecationRegistry
 * @notice Defines “Rehypothecation” models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RehypothecationRegistry {
    /// @notice Types of rehypothecation agreements
    enum RehypothecationType {
        Full,             // full rehypothecation of collateral
        Partial,          // partial rehypothecation allowed
        TriParty,         // tri‐party rehypothecation structure
        Segregated,       // collateral held separately, no rehypothecation
        LockupPeriod      // rehypothecation only after a lockup period
    }

    /// @notice Attack vectors exploiting rehypothecation
    enum AttackType {
        CollateralShortage,  // over-lending leads to insufficient collateral
        SystemicRisk,        // cascading failures due to chained rehypothecation
        CounterpartyDefault, // default by one party breaks downstream obligations
        Misreporting,        // falsifying collateral availability
        MaturityMismatch     // mismatched collateral/liability maturities
    }

    /// @notice Defense mechanisms for managing rehypothecation risk
    enum DefenseType {
        CollateralHaircut,   // take haircut on collateral value
        PositionLimits,      // cap on rehypothecation exposure
        SegregatedAccounts,  // segregate client collateral by default
        TransparencyReporting, // regular on-chain collateral reporting
        MarginCalls          // automated margin calls on collateral shortfall
    }

    struct Term {
        RehypothecationType model;
        AttackType          attack;
        DefenseType         defense;
        uint256             timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed        id,
        RehypothecationType    model,
        AttackType             attack,
        DefenseType            defense,
        uint256                timestamp
    );

    /**
     * @notice Register a new Rehypothecation term.
     * @param model   The rehypothecation model type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id     The ID of the newly registered term.
     */
    function registerTerm(
        RehypothecationType model,
        AttackType          attack,
        DefenseType         defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            model:     model,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, model, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return model     The rehypothecation model type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RehypothecationType model,
            AttackType          attack,
            DefenseType         defense,
            uint256             timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.model, t.attack, t.defense, t.timestamp);
    }
}
