// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SeedFundingRegistry
 * @notice Defines “Seed Funding” stages along with common
 *         attack vectors (risks) and defense mechanisms. Users can
 *         register and query these combinations on-chain for analysis or governance.
 */
contract SeedFundingRegistry {
    /// @notice Types of seed funding rounds
    enum SeedType {
        FriendsAndFamily,   // informal funding from personal network
        AngelRound,         // investment from angel investors
        PreSeed,            // very early-stage institutional funding
        IncubatorAccelerator, // funding via incubator or accelerator program
        StrategicPartner    // funding from strategic corporate partner
    }

    /// @notice Risk vectors in seed funding
    enum AttackType {
        EquityDilution,     // overly large raises diluting founders
        CapTableManipulation, // altering ownership records maliciously
        MisuseOfFunds,      // deploying funds outside agreed use
        FraudulentValuation,// inflating or misrepresenting valuation
        RegulatoryNoncompliance // failing to comply with securities laws
    }

    /// @notice Defense mechanisms for seed funding security
    enum DefenseType {
        VestingSchedules,   // vest founder/employee equity over time
        CapTableAudits,     // regular third-party cap-table reviews
        FundsEscrow,        // hold funds in escrow until milestones
        TransparentReporting, // on-chain tracking of fund disbursement
        LegalCompliance     // on-chain verification of KYC/AML and filings
    }

    struct Term {
        SeedType    seedRound;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        SeedType      seedRound,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Seed Funding term.
     * @param seedRound The seed funding round type.
     * @param attack    The anticipated risk or attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        SeedType    seedRound,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            seedRound: seedRound,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, seedRound, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Seed Funding term.
     * @param id The term ID.
     * @return seedRound  The seed funding round type.
     * @return attack     The risk or attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            SeedType    seedRound,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.seedRound, t.attack, t.defense, t.timestamp);
    }
}
