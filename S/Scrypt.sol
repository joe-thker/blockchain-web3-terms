// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScryptRegistry
 * @notice Defines “Scrypt” key-derivation function variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ScryptRegistry {
    /// @notice Variants of the scrypt KDF parameters
    enum ScryptVariant {
        Default,        // N=2^14, r=8, p=1
        Moderate,       // N=2^15, r=8, p=1
        MemoryHard,     // N=2^16, r=8, p=1
        CPUHard,        // N=2^14, r=8, p=2
        Custom          // user-defined N, r, p
    }

    /// @notice Attack vectors targeting scrypt operations
    enum AttackType {
        GPUAcceleration, // using GPUs to speed up KDF
        ASICDeployment,  // specialized hardware for scrypt
        SideChannel,     // leaking via timing/power analysis
        LowMemoryAttack, // forcing low-memory fallback
        ParameterMischief // tricking into insecure parameter choice
    }

    /// @notice Defense mechanisms for secure scrypt usage
    enum DefenseType {
        EnforcedParams,   // require minimum N,r,p parameters on-chain
        RateLimiting,     // throttle KDF invocations per address/time
        ConstantTime,     // implement true constant-time routines
        MemoryChecks,     // verify memory usage before execution
        MultiFactorKDF    // combine with PBKDF2 or Argon2 for extra hardness
    }

    struct Term {
        ScryptVariant variant;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed  id,
        ScryptVariant    variant,
        AttackType       attack,
        DefenseType      defense,
        uint256          timestamp
    );

    /**
     * @notice Register a new Scrypt term.
     * @param variant  The scrypt parameter variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        ScryptVariant variant,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            variant:   variant,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, variant, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Scrypt term.
     * @param id The term ID.
     * @return variant   The scrypt parameter variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ScryptVariant variant,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.variant, t.attack, t.defense, t.timestamp);
    }
}
