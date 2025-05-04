// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScholarshipRegistry
 * @notice Defines “Scholarship” program types along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ScholarshipRegistry {
    /// @notice Types of scholarship programs
    enum ScholarshipType {
        MeritBased,        // awarded for academic excellence
        NeedBased,         // awarded based on financial need
        Athletic,          // awarded for sports achievements
        Diversity,         // awarded to underrepresented groups
        Research,          // funding for academic research
        Creative,          // awarded for arts and creativity
        Talent             // awarded for specific talents or skills
    }

    /// @notice Attack vectors targeting scholarship programs
    enum AttackType {
        FraudulentApplication, // submitting false application info
        DocumentForgery,       // forging transcripts or recommendation letters
        Bribery,               // attempting to influence decision makers
        IdentityTheft,         // using someone else’s identity to apply
        GPAManipulation        // colluding to alter GPA records
    }

    /// @notice Defense mechanisms to secure scholarship programs
    enum DefenseType {
        VerifiedCredentials,   // on-chain verification of academic records
        KYCVerification,       // identity verification for applicants
        AuditTrail,            // immutable on-chain logs of decisions
        ThirdPartyValidation,  // independent verification by external bodies
        RandomAudits           // periodic spot checks of awarded scholarships
    }

    struct Term {
        ScholarshipType program;
        AttackType      attack;
        DefenseType     defense;
        uint256         timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        ScholarshipType    program,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Scholarship term.
     * @param program The scholarship program type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        ScholarshipType program,
        AttackType      attack,
        DefenseType     defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            program:   program,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, program, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Scholarship term.
     * @param id The term ID.
     * @return program   The scholarship program type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ScholarshipType program,
            AttackType      attack,
            DefenseType     defense,
            uint256         timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.program, t.attack, t.defense, t.timestamp);
    }
}
