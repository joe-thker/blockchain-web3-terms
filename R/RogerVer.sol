// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RogerVerRegistry
 * @notice Defines “Roger Ver” profile roles along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RogerVerRegistry {
    /// @notice Known roles or capacities of Roger Ver
    enum RoleType {
        Investor,        // early Bitcoin investor
        Advocate,        // proponent of Bitcoin Cash
        Entrepreneur,    // serial crypto entrepreneur
        Speaker,         // public speaker at events
        Author           // writer on crypto topics
    }

    /// @notice Attack vectors targeting public figures like Roger Ver
    enum AttackType {
        Misinformation,  // spreading false claims or rumors
        Phishing,        // impersonation attempts via email/links
        Doxing,          // leaking personal information
        DDoS,            // denial-of-service on his services
        RegulatoryPress  // attempts to force legal restrictions
    }

    /// @notice Defense mechanisms for protecting public figures
    enum DefenseType {
        FactChecking,    // official clarifications and corrections
        SecureAuth,      // enforce multi-factor authentication
        PrivacyMeasures, // minimize personal data exposure
        LegalAction,     // pursue legal recourse against attackers
        CommunitySupport // rally community defense and awareness
    }

    struct Term {
        RoleType   role;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RoleType      role,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Roger Ver term.
     * @param role    The role or capacity.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id     The ID of the newly registered term.
     */
    function registerTerm(
        RoleType    role,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            role:      role,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, role, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return role      The role or capacity.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RoleType    role,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.role, t.attack, t.defense, t.timestamp);
    }
}
