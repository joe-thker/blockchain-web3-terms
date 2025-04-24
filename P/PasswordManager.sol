// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PasswordManagerRegistry
 * @notice Defines “Password Manager” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PasswordManagerRegistry {
    /// @notice Types of password managers
    enum PasswordManagerType {
        CloudBased,       // hosted in the cloud
        LocalApp,         // local desktop or mobile application
        BrowserExtension, // integrated into a web browser
        HardwareDevice,   // standalone hardware key manager
        SelfHosted        // user-hosted server solution
    }

    /// @notice Attack vectors targeting password managers
    enum AttackType {
        Phishing,         // tricking user into revealing credentials
        Keylogging,       // capturing keystrokes on device
        BruteForce,       // guessing master password
        MalwareInjection, // injecting malicious code into manager
        InsiderThreat     // compromise by trusted party
    }

    /// @notice Defense mechanisms for password managers
    enum DefenseType {
        Encryption,            // strong encryption of stored data
        MultiFactorAuth,       // require second factor on access
        HardwareSecurityModule,// isolate keys in secure hardware
        SecureBackup,          // encrypted off-site backups
        AccessControl          // role-based or time-based access policies
    }

    struct Term {
        PasswordManagerType pmType;
        AttackType          attack;
        DefenseType         defense;
        uint256             timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PasswordManagerType pmType,
        AttackType          attack,
        DefenseType         defense,
        uint256             timestamp
    );

    /**
     * @notice Register a new Password Manager term.
     * @param pmType  The password manager implementation type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PasswordManagerType pmType,
        AttackType          attack,
        DefenseType         defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            pmType:    pmType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, pmType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Password Manager term.
     * @param id The term ID.
     * @return pmType    The password manager type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PasswordManagerType pmType,
            AttackType          attack,
            DefenseType         defense,
            uint256             timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.pmType, t.attack, t.defense, t.timestamp);
    }
}
