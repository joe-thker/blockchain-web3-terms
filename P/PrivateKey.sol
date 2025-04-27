// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PrivateKeyRegistry
 * @notice Defines “Private Key/Secret Key” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PrivateKeyRegistry {
    /// @notice Types of private/secret key storage
    enum KeyType {
        HotWallet,         // keys stored in an online wallet
        ColdWallet,        // keys stored offline (e.g. air-gapped)
        HardwareWallet,    // keys in a hardware device
        PaperWallet,       // printed or written key material
        BrainWallet        // key derived from a memorized passphrase
    }

    /// @notice Attack vectors targeting private/secret keys
    enum AttackType {
        Phishing,          // tricking user to reveal their key
        Keylogging,        // malware capturing keystrokes
        BruteForce,        // guessing weak passphrases
        SocialEngineering, // manipulating user to hand over keys
        ManInTheMiddle     // intercepting key exchange or backup
    }

    /// @notice Defense mechanisms for protecting private/secret keys
    enum DefenseType {
        Encryption,           // encrypt key material at rest
        MultiFactorAuth,      // require additional auth factors
        HSMIsolation,         // isolate keys in hardware security modules
        AirgappedStorage,     // keep keys on devices never touched by internet
        ShardedBackups        // split key into shares for safe backup
    }

    struct Term {
        KeyType    keyType;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        KeyType    keyType,
        AttackType attack,
        DefenseType defense,
        uint256    timestamp
    );

    /**
     * @notice Register a new Private Key/Secret Key term.
     * @param keyType  The storage category of the key.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        KeyType    keyType,
        AttackType attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            keyType:    keyType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, keyType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return keyType   The key storage category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            KeyType    keyType,
            AttackType attack,
            DefenseType defense,
            uint256    timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.keyType, t.attack, t.defense, t.timestamp);
    }
}
