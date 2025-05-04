// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScriptingLanguageRegistry
 * @notice Defines “Scripting Programming Language” variants along with common
 *         attack vectors and defense mechanisms. Users can register and query
 *         these combinations on-chain for analysis or governance.
 */
contract ScriptingLanguageRegistry {
    /// @notice Variants of scripting languages
    enum LanguageType {
        JavaScript,        // ubiquitous web scripting
        Python,            // general-purpose high-level scripting
        Bash,              // Unix shell scripting
        Lua,               // embeddable lightweight scripting
        Ruby               // dynamic object-oriented scripting
    }

    /// @notice Attack vectors in scripting language contexts
    enum AttackType {
        CodeInjection,     // unsanitized input executed as code
        CommandInjection,  // unvalidated shell commands execution
        PrototypePollution,// JS object prototype tampering
        Deserialization,   // unsafe object deserialization
        InfiniteLoop       // denial-of-service via looping
    }

    /// @notice Defense mechanisms for scripting languages
    enum DefenseType {
        InputSanitization, // escape or validate all inputs
        Sandboxing,        // run scripts in isolated environment
        CSP,               // Content Security Policy for JS
        SafeDeserialize,   // use secure deserialization libraries
        TimeoutLimits      // enforce execution time limits
    }

    struct Term {
        LanguageType language;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        LanguageType      language,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new Scripting Language term.
     * @param language The scripting language variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        LanguageType language,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            language:  language,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, language, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Scripting Language term.
     * @param id The term ID.
     * @return language  The scripting language variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            LanguageType language,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.language, t.attack, t.defense, t.timestamp);
    }
}
