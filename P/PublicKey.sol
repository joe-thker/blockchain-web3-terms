// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PublicKeyRegistry
 * @notice Defines “Public Key” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PublicKeyRegistry {
    /// @notice Types of public key algorithms
    enum PublicKeyType {
        RSA2048,           // RSA with 2048-bit modulus
        RSA4096,           // RSA with 4096-bit modulus
        ECDSA_SECP256K1,   // ECDSA over secp256k1 curve
        ED25519,           // Edwards-curve Digital Signature Algorithm
        SCHNORR             // Schnorr signature scheme
    }

    /// @notice Attack vectors targeting public keys
    enum AttackType {
        BruteForce,         // trying all possible keys
        SideChannel,        // leaking key material via implementation
        FaultInjection,     // inducing errors to extract secrets
        QuantumAttack,      // using quantum algorithms (Shor’s)
        KeySpoofing         // presenting a forged or wrong key
    }

    /// @notice Defense mechanisms for protecting public keys
    enum DefenseType {
        AdequateKeyLength,      // use sufficiently long keys
        HSMStorage,             // store keys in hardware security modules
        MultiFactorAuth,        // require multiple factors for use
        ThresholdSignatures,    // split key into shares (M-of-N)
        PostQuantumAlgorithms   // use quantum-resistant schemes
    }

    struct Term {
        PublicKeyType keyType;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        PublicKeyType      keyType,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Public Key term.
     * @param keyType The public key algorithm type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PublicKeyType keyType,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            keyType:   keyType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, keyType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Public Key term.
     * @param id The term ID.
     * @return keyType   The public key algorithm type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PublicKeyType keyType,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.keyType, t.attack, t.defense, t.timestamp);
    }
}
