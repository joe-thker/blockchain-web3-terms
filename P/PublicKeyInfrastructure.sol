// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PublicKeyCryptoRegistry
 * @notice Defines “Public-Key Cryptography” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract PublicKeyCryptoRegistry {
    /// @notice Types of public-key cryptography algorithms
    enum PKCType {
        RSA,                // Rivest–Shamir–Adleman
        ECC,                // Elliptic Curve Cryptography
        ElGamal,            // ElGamal encryption
        DSA,                // Digital Signature Algorithm
        PostQuantum         // lattice- or code-based post-quantum schemes
    }

    /// @notice Attack vectors targeting public-key cryptography
    enum AttackType {
        KeyLeak,            // theft or leakage of private key
        MITM,               // man-in-the-middle interception
        SideChannel,        // timing, power, or electromagnetic analysis
        ReplayAttack,       // reuse of old signatures or ciphertexts
        QuantumBreak        // future quantum attacks on classical schemes
    }

    /// @notice Defense mechanisms for public-key cryptography
    enum DefenseType {
        KeyLength,          // use sufficiently large key sizes
        HSMStorage,         // store keys in hardware security modules
        ConstantTimeOps,    // implement operations in constant time
        NonceUsage,         // include nonces/ephemerals to prevent replays
        PQSchemes           // deploy quantum-resistant algorithms
    }

    struct Term {
        PKCType     algorithm;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PKCType     algorithm,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Public-Key Cryptography term.
     * @param algorithm The PKC algorithm type.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        PKCType     algorithm,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            algorithm: algorithm,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, algorithm, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return algorithm The PKC algorithm type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PKCType     algorithm,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.algorithm, t.attack, t.defense, t.timestamp);
    }
}
