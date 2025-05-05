// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SeedPhraseRegistry
 * @notice Defines “Seed Phrase” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract SeedPhraseRegistry {
    /// @notice Variants of seed phrase schemes
    enum PhraseType {
        BIP39_12,          // 12-word BIP-39 mnemonic
        BIP39_24,          // 24-word BIP-39 mnemonic
        CustomLength,      // user-defined length mnemonic
        PassphraseExtended,// mnemonic + optional passphrase
        ShamirBackup       // Shamir’s Secret Sharing shards
    }

    /// @notice Attack vectors against seed phrases
    enum AttackType {
        Phishing,          // trick user into entering phrase on fake site
        ClipboardSteal,    // malware reading clipboard contents
        Keylogger,         // capturing typed words
        BruteForce,        // guessing short/custom mnemonics
        PhysicalTheft      // stealing written backup
    }

    /// @notice Defense mechanisms for protecting seed phrases
    enum DefenseType {
        HardwareWallet,    // store phrase in secure hardware
        EncryptedStorage,  // encrypted digital backup
        PassphraseMask,    // require extra passphrase to derive keys
        OfflineAirgap,     // never expose phrase on an internet device
        ShamirSharing      // split phrase into multiple shares
    }

    struct Term {
        PhraseType phrase;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PhraseType     phrase,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new Seed Phrase term.
     * @param phrase   The seed phrase variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PhraseType  phrase,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            phrase:    phrase,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, phrase, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Seed Phrase term.
     * @param id The term ID.
     * @return phrase    The seed phrase variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PhraseType  phrase,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.phrase, t.attack, t.defense, t.timestamp);
    }
}
