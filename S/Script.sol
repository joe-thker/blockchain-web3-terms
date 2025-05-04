// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScriptRegistry
 * @notice Defines “Script” categories (in blockchain scripting languages) along with common
 *         attack vectors and defense mechanisms. Users can register and query these combinations
 *         on-chain for analysis or governance.
 */
contract ScriptRegistry {
    /// @notice Types of scripts
    enum ScriptType {
        LockScript,        // specifies conditions to spend UTXO
        UnlockScript,      // proves conditions to redeem UTXO
        SmartContract,     // full Turing-complete contract code
        MultiSigScript,    // requires multiple signatures to execute
        TimeLockScript     // enforces time-based spending restrictions
    }

    /// @notice Attack vectors targeting scripts
    enum AttackType {
        ScriptReentrancy,  // recursive calls to drain funds
        MalformedData,     // feeding unexpected data to break logic
        SignatureForgery,  // crafting fake signatures to satisfy conditions
        ReplayAttack,      // replaying valid scripts on forks
        IntegerOverflow    // overflow/underflow in script arithmetic
    }

    /// @notice Defense mechanisms for secure scripting
    enum DefenseType {
        ChecksEffectsPatterns, // follow checks-effects-interactions
        InputValidation,       // strictly validate all inputs
        NonReentrantGuard,     // use reentrancy guards on contract calls
        StrongTyping,          // enforce explicit type checks
        FormalVerification     // use formal methods to prove script safety
    }

    struct Term {
        ScriptType  scriptVariant;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ScriptType    scriptVariant,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Script term.
     * @param scriptVariant The script category.
     * @param attack        The anticipated attack vector.
     * @param defense       The chosen defense mechanism.
     * @return id           The ID of the newly registered term.
     */
    function registerTerm(
        ScriptType  scriptVariant,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            scriptVariant: scriptVariant,
            attack:        attack,
            defense:       defense,
            timestamp:     block.timestamp
        });
        emit TermRegistered(id, scriptVariant, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Script term.
     * @param id The term ID.
     * @return scriptVariant The script category.
     * @return attack        The attack vector.
     * @return defense       The defense mechanism.
     * @return timestamp     When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ScriptType  scriptVariant,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.scriptVariant, t.attack, t.defense, t.timestamp);
    }
}
