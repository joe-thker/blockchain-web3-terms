// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScammerRegistry
 * @notice Defines “Scammer” profiles along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ScammerRegistry {
    /// @notice Categories of scammers
    enum ScammerType {
        Phishing,            // impersonates trusted entities via email/links
        Vishing,             // voice-call based phishing
        TechSupportFraud,    // fake tech support to gain access
        RomanceScam,         // social engineering via dating sites
        InvestmentFraud      // fake investment opportunities
    }

    /// @notice Attack vectors used by scammers
    enum AttackType {
        MaliciousLink,       // links leading to credential theft
        SpoofedCallerID,     // faked phone numbers or identities
        FakeSoftware,        // malicious downloads posing as updates
        FakeProfile,         // counterfeit social profiles
        PonziPromise         // promises of unrealistic returns
    }

    /// @notice Defense mechanisms against scammer tactics
    enum DefenseType {
        SpamFilter,          // email/URL filtering and blocking
        CallerIDVerification,// authenticating incoming call sources
        SafeDownloadChecks,  // verifying signatures of software
        ProfileVerification, // verifying social identities on-chain
        RegulatoryReporting  // on-chain reporting & blacklisting
    }

    struct Term {
        ScammerType  profile;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ScammerType    profile,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new Scammer term.
     * @param profile The scammer category.
     * @param attack  The attack vector they employ.
     * @param defense The recommended defense mechanism.
     * @return id     The ID of the newly registered term.
     */
    function registerTerm(
        ScammerType profile,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            profile:   profile,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, profile, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Scammer term.
     * @param id The term ID.
     * @return profile   The scammer category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ScammerType profile,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.profile, t.attack, t.defense, t.timestamp);
    }
}
