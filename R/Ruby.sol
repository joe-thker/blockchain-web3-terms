// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RubyRegistry
 * @notice Defines “Ruby (Programming Language)” feature variants along with common
 *         attack vectors and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract RubyRegistry {
    /// @notice Variants of Ruby language features
    enum RubyType {
        Interpreted,         // code executed by an interpreter
        DynamicTyping,       // types checked at runtime
        ObjectOriented,      // pure object model (everything is an object)
        Metaprogramming,     // code can modify its own structure
        GarbageCollected     // automatic memory management
    }

    /// @notice Common attack vectors in Ruby applications
    enum AttackType {
        CodeInjection,       // untrusted input passed to eval or exec
        GemVulnerability,    // compromised or outdated library dependencies
        UnsafeDeserialization, // insecure YAML/Marshal loading
        DirectoryTraversal,  // file operations with unvalidated paths
        MemoryLeak           // excessive object retention leading to OOM
    }

    /// @notice Defense mechanisms for securing Ruby applications
    enum DefenseType {
        InputSanitization,   // validate and sanitize all user input
        DependencyPinning,   // lock gem versions and audit dependencies
        SafeDeserialization, // use JSON or safe load options
        PathNormalization,   // enforce canonical file paths
        MemoryProfiling      // monitor and free unused objects
    }

    struct Term {
        RubyType     feature;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RubyType      feature,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Ruby term.
     * @param feature  The Ruby feature variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        RubyType     feature,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            feature:   feature,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, feature, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Ruby term.
     * @param id The term ID.
     * @return feature   The Ruby feature variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RubyType     feature,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.feature, t.attack, t.defense, t.timestamp);
    }
}
