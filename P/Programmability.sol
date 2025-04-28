// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProgrammabilityRegistry
 * @notice Defines “Programmability” capabilities along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ProgrammabilityRegistry {
    /// @notice Types of programmability models
    enum ProgrammabilityType {
        TuringComplete,      // full general-purpose smart contracts
        DomainSpecific,      // DSLs for particular use-cases
        LimitedScript,       // constrained on-chain scripts (e.g. Bitcoin Script)
        EventDriven,         // logic triggered by chain events
        Parameterized        // configurable logic via parameters
    }

    /// @notice Attack vectors targeting programmable contracts
    enum AttackType {
        Reentrancy,          // attacker re-enters contract to steal funds
        GasLimitDoS,         // malicious loops to exhaust block gas
        IntegerOverflow,     // arithmetic overflows/underflows
        AccessControlMisconfig, // improper permission checks
        ScriptInjection      // injecting untrusted logic/data
    }

    /// @notice Defense mechanisms for programmable systems
    enum DefenseType {
        ReentrancyGuard,     // protect against reentrant calls
        GasLimitChecks,      // cap iterations or gas usage
        SafeMath,            // use checked arithmetic libraries
        AccessControl,       // robust role-based permissions
        FormalVerification   // mathematically verify contract correctness
    }

    struct Term {
        ProgrammabilityType progType;
        AttackType          attack;
        DefenseType         defense;
        uint256             timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ProgrammabilityType progType,
        AttackType          attack,
        DefenseType         defense,
        uint256             timestamp
    );

    /**
     * @notice Register a new Programmability term.
     * @param progType The programmability model type.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        ProgrammabilityType progType,
        AttackType          attack,
        DefenseType         defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            progType:  progType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, progType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Programmability term.
     * @param id The term ID.
     * @return progType The programmability model type.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ProgrammabilityType progType,
            AttackType          attack,
            DefenseType         defense,
            uint256             timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.progType, t.attack, t.defense, t.timestamp);
    }
}
