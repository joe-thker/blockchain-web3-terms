// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RecursionRegistry
 * @notice Defines “Recursion” patterns along with common
 *         attack vectors (risks) and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RecursionRegistry {
    /// @notice Types of recursion patterns
    enum RecursionType {
        Direct,            // function calls itself directly
        Indirect,          // recursion via helper functions
        TailRecursive,     // recursive call is the last operation
        Mutual,            // two or more functions call each other
        Nested             // recursion within nested loops or calls
    }

    /// @notice Attack vectors (risks) in recursive logic
    enum AttackType {
        Reentrancy,        // unexpected external calls during recursion
        StackOverflow,     // exceeding call stack depth
        InfiniteLoop,      // missing base case leading to hang
        GasExhaustion,     // deep recursion consuming all gas
        StateInconsistency // partial updates leading to invalid state
    }

    /// @notice Defense mechanisms for safe recursion
    enum DefenseType {
        DepthLimit,            // enforce maximum recursion depth
        ChecksEffects,         // apply checks-effects-interactions pattern
        TailCallOptimization,  // rewrite to tail calls if supported
        GasGuard,              // track and require minimum remaining gas
        ExplicitStacks         // replace recursion with manual stack data
    }

    struct Term {
        RecursionType recursionPattern;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed   id,
        RecursionType     recursionPattern,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new Recursion term.
     * @param recursionPattern The recursion pattern type.
     * @param attack           The anticipated attack/risk vector.
     * @param defense          The chosen defense mechanism.
     * @return id              The ID of the newly registered term.
     */
    function registerTerm(
        RecursionType recursionPattern,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            recursionPattern: recursionPattern,
            attack:           attack,
            defense:          defense,
            timestamp:        block.timestamp
        });
        emit TermRegistered(id, recursionPattern, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Recursion term.
     * @param id The term ID.
     * @return recursionPattern The recursion pattern type.
     * @return attack           The attack/risk vector.
     * @return defense          The defense mechanism.
     * @return timestamp        When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RecursionType recursionPattern,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.recursionPattern, t.attack, t.defense, t.timestamp);
    }
}
