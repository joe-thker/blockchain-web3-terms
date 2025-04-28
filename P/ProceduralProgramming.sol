// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProceduralProgrammingRegistry
 * @notice Defines “Procedural Programming” paradigms along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ProceduralProgrammingRegistry {
    /// @notice Types of procedural programming paradigms
    enum ProceduralType {
        Imperative,     // direct step-by-step instructions
        Structured,     // use of control structures (if, loops)
        Modular,        // decomposition into reusable modules
        EventDriven,    // execution based on event handlers
        Batch           // sequential batch processing
    }

    /// @notice Attack vectors targeting procedural code
    enum AttackType {
        SpaghettiCode,      // unstructured, tangled control flow
        LogicBomb,         // hidden malicious logic triggers
        RaceCondition,     // unsynchronized access leads to errors
        BufferOverflow,    // out-of-bounds memory writes
        DataCorruption     // unintended modification of shared state
    }

    /// @notice Defense mechanisms for procedural systems
    enum DefenseType {
        CodeModularity,     // isolate functionality into small units
        InputValidation,    // check all inputs before use
        StaticAnalysis,     // automated code scanning tools
        MemorySafety,       // bounds checks and safe allocation
        CodeReviews         // peer review and style enforcement
    }

    struct Term {
        ProceduralType ppType;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ProceduralType ppType,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new Procedural Programming term.
     * @param ppType   The procedural paradigm type.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        ProceduralType ppType,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            ppType:    ppType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, ppType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Procedural Programming term.
     * @param id  The term ID.
     * @return ppType   The procedural paradigm type.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ProceduralType ppType,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.ppType, t.attack, t.defense, t.timestamp);
    }
}
