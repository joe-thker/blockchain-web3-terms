// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RansomwareRegistry
 * @notice Defines “Ransomware” variants along with common attack vectors
 *         and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract RansomwareRegistry {
    /// @notice Types of ransomware
    enum RansomwareType {
        CryptoLocker,      // encrypts files and demands ransom for decryption key
        Locker,            // locks the system UI until ransom is paid
        Scareware,         // fake alerts demanding payment to remove threats
        Doxware,           // threatens to release stolen data
        RaaS               // Ransomware-as-a-Service platforms
    }

    /// @notice Attack vectors used in ransomware campaigns
    enum AttackType {
        PhishingEmail,     // social engineering via malicious attachments/links
        ExploitKit,        // drive-by downloads via compromised websites
        MaliciousAd,       // malvertising delivering ransomware payload
        RemoteDesktop,     // brute-forcing or exploiting RDP
        SupplyChain        // infecting through trusted software updates
    }

    /// @notice Defense mechanisms against ransomware
    enum DefenseType {
        RegularBackups,     // frequent offline or immutable backups
        EndpointProtection, // anti-malware and behavioral detection tools
        PatchManagement,    // timely OS/app vulnerability patching
        NetworkSegmentation,// restrict lateral movement within the network
        UserTraining        // educate users to recognize phishing/social engineering
    }

    struct Term {
        RansomwareType ransomwareType;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        RansomwareType     ransomwareType,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Ransomware term.
     * @param ransomwareType The ransomware variant.
     * @param attack         The anticipated attack vector.
     * @param defense        The chosen defense mechanism.
     * @return id            The ID of the newly registered term.
     */
    function registerTerm(
        RansomwareType ransomwareType,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            ransomwareType: ransomwareType,
            attack:         attack,
            defense:        defense,
            timestamp:      block.timestamp
        });
        emit TermRegistered(id, ransomwareType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Ransomware term.
     * @param id The term ID.
     * @return ransomwareType The ransomware variant.
     * @return attack         The attack vector.
     * @return defense        The defense mechanism.
     * @return timestamp      When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RansomwareType ransomwareType,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.ransomwareType, t.attack, t.defense, t.timestamp);
    }
}
