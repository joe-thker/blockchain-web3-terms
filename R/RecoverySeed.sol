// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RecoverySeedRegistry
 * @notice Defines “Recovery Seed” methods along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RecoverySeedRegistry {
    /// @notice Types of recovery seed methods
    enum SeedType {
        BIP39Mnemonic,      // 12/24-word mnemonic phrases
        ShamirSecretSharing,// split seed into M-of-N shares
        HardwareBackup,     // stored in hardware device backup
        SocialRecovery,     // recovery via trusted contacts
        MultiFactorSeed     // combine seed with 2FA or PIN
    }

    /// @notice Attack vectors targeting recovery seeds
    enum AttackType {
        Phishing,           // trick user into revealing seed
        Keylogger,          // malware capturing typed seed
        ClipboardHijack,    // intercept seed copied to clipboard
        PhysicalTheft,      // stealing written seed from storage
        InsiderThreat       // compromised custodian in social recovery
    }

    /// @notice Defense mechanisms for securing recovery seeds
    enum DefenseType {
        EncryptedStorage,   // encrypt seed when at rest
        AirGappedEntry,     // enter seed on offline device
        SeedSharding,       // split seed across multiple locations
        MultiSigRecovery,   // require multiple approvals to reconstruct
        TimeLockRecovery    // time-delayed recovery to allow abort
    }

    struct Term {
        SeedType    seedType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        SeedType    seedType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Recovery Seed term.
     * @param seedType  The recovery seed method variant.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        SeedType    seedType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            seedType:  seedType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, seedType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Recovery Seed term.
     * @param id The term ID.
     * @return seedType  The recovery seed method variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            SeedType    seedType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.seedType, t.attack, t.defense, t.timestamp);
    }
}
