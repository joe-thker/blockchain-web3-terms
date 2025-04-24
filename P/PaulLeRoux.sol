// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PaulLeRouxRegistry
 * @notice Defines “Paul Le Roux” activity categories along with
 *         common enforcement (attack) vectors and defense mechanisms.
 *         Users can register and query these combinations on-chain.
 */
contract PaulLeRouxRegistry {
    /// @notice Categories of activities attributed to Paul Le Roux
    enum PLRType {
        DrugTrafficking,    // large-scale narcotics smuggling
        ArmsTrafficking,    // illegal weapons distribution
        MoneyLaundering,    // concealment of illicit proceeds
        CyberCrime,         // hacking, ransomware operations
        OrganizedCrime      // leadership of criminal network
    }

    /// @notice Enforcement actions (“attacks”) against him
    enum AttackType {
        LawEnforcement,     // arrests and raids by police/FBI
        Extradition,        // transfer to face foreign charges
        AssetFreezing,      // seizing bank accounts and property
        UndercoverOps,      // infiltration by undercover agents
        CyberCounterOps     // digital disruption of his infrastructure
    }

    /// @notice Legal defenses and mitigation strategies
    enum DefenseType {
        LegalCounsel,       // hiring defense attorneys
        PleaBargain,        // negotiating reduced charges
        WitnessProtection,  // protection in exchange for testimony
        ExtraditionContest, // legal challenge to extradition
        DiplomaticImmunity  // invoking political asylum/immunity
    }

    struct Term {
        PLRType      activity;
        AttackType   enforcement;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PLRType      activity,
        AttackType   enforcement,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Paul Le Roux term.
     * @param activity     The category of his activity.
     * @param enforcement  The enforcement action taken.
     * @param defense      The defense mechanism used.
     * @return id          The ID of the registered term.
     */
    function registerTerm(
        PLRType      activity,
        AttackType   enforcement,
        DefenseType  defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            activity:    activity,
            enforcement: enforcement,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit TermRegistered(id, activity, enforcement, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return activity     The activity category.
     * @return enforcement  The enforcement action.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PLRType      activity,
            AttackType   enforcement,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.activity, t.enforcement, t.defense, t.timestamp);
    }
}
