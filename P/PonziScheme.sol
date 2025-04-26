// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PonziSchemeRegistry
 * @notice Defines “Ponzi Scheme” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on‐chain for analysis or governance.
 */
contract PonziSchemeRegistry {
    /// @notice Types of Ponzi schemes
    enum PonziType {
        MultiLevel,           // classic pyramid recruitment
        Matrix,               // fixed‐matrix levels with overflow
        ChainLetter,          // mailing‐list style promises
        HYIP,                 // High‐Yield Investment Program
        CryptoReferral        // token‐referral‐based scheme
    }

    /// @notice Attack vectors in Ponzi schemes
    enum AttackType {
        RecruitmentScam,      // luring new investors with false promises
        FakeAudits,           // fabricated proof of returns
        ExitScam,             // creators abscond with funds
        RegulatoryEvasion,    // operating outside legal frameworks
        InsiderMisappropriation // internal theft of funds
    }

    /// @notice Defense mechanisms against Ponzi schemes
    enum DefenseType {
        TransparencyReports,  // publish real‐time fund flows
        IndependentAudits,    // third‐party financial reviews
        RegulatoryCompliance, // adhere to securities regulations
        EscrowProtections,    // hold contributions in escrow
        WhistleblowerHotline  // enable reporting of fraud
    }

    struct Term {
        PonziType   schemeType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PonziType   schemeType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Ponzi Scheme term.
     * @param schemeType The category of Ponzi scheme.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        PonziType   schemeType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            schemeType: schemeType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, schemeType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Ponzi Scheme term.
     * @param id The term ID.
     * @return schemeType The Ponzi scheme category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PonziType   schemeType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.schemeType, t.attack, t.defense, t.timestamp);
    }
}
