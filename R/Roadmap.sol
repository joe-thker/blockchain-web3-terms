// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RoadmapRegistry
 * @notice Defines “Roadmap” milestone types along with common
 *         attack vectors (risks) and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RoadmapRegistry {
    /// @notice Types of roadmap milestones
    enum MilestoneType {
        WhitepaperRelease,    // publication of project whitepaper
        TestnetLaunch,        // deployment of test network
        MainnetLaunch,        // launch of main network
        TokenListing,         // listing on exchanges
        GovernanceActivation  // activation of on-chain governance
    }

    /// @notice Attack vectors or risks to roadmap progress
    enum AttackType {
        Delay,                // unexpected delays in milestone delivery
        ScopeCreep,           // additional features causing schedule slip
        FundingShortfall,     // insufficient funds to complete milestone
        RegulatoryHurdle,     // legal obstacles delaying work
        TechnicalDebt         // accumulating issues slowing progress
    }

    /// @notice Defense mechanisms or mitigations for roadmap risks
    enum DefenseType {
        TimeBuffer,           // add buffer time to schedule estimates
        ModularPhases,        // break roadmap into independent phases
        EscrowFunding,        // release funds upon milestone completion
        ExternalAudit,        // third-party review of progress
        GovernanceVoting      // community votes on roadmap changes
    }

    struct Term {
        MilestoneType milestone;
        AttackType    risk;
        DefenseType   mitigation;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed   id,
        MilestoneType     milestone,
        AttackType        risk,
        DefenseType       mitigation,
        uint256           timestamp
    );

    /**
     * @notice Register a new Roadmap term.
     * @param milestone   The roadmap milestone type.
     * @param risk        The anticipated risk/attack vector.
     * @param mitigation  The chosen defense/mitigation mechanism.
     * @return id         The ID of the newly registered term.
     */
    function registerTerm(
        MilestoneType milestone,
        AttackType    risk,
        DefenseType   mitigation
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            milestone:  milestone,
            risk:       risk,
            mitigation: mitigation,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, milestone, risk, mitigation, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Roadmap term.
     * @param id The term ID.
     * @return milestone   The roadmap milestone type.
     * @return risk        The risk/attack vector.
     * @return mitigation  The defense/mitigation mechanism.
     * @return timestamp   When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            MilestoneType milestone,
            AttackType    risk,
            DefenseType   mitigation,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.milestone, t.risk, t.mitigation, t.timestamp);
    }
}
