// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RenewableEnergyRegistry
 * @notice Defines “Renewable Energy” project categories along with common
 *         attack vectors (risks) and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RenewableEnergyRegistry {
    /// @notice Types of renewable energy projects
    enum EnergyType {
        Solar,            // photovoltaic or solar thermal installations
        Wind,             // onshore or offshore wind farms
        Hydro,            // hydropower dams or run-of-river
        Geothermal,       // geothermal plant harnessing earth heat
        Biomass           // biofuel or biogas energy generation
    }

    /// @notice Attack vectors or risks for renewable energy assets
    enum AttackType {
        PhysicalSabotage,   // vandalism or tampering with equipment
        CyberAttack,        // hacking SCADA or control systems
        NaturalDisaster,    // storms, floods, earthquakes damage assets
        SupplyChainDisruption, // disruption in parts or fuel delivery
        RegulatoryChange    // policy shifts reducing project viability
    }

    /// @notice Defense mechanisms or mitigations for these risks
    enum DefenseType {
        SurveillanceSystems, // cameras, drones monitoring sites
        SecureFirmware,      // hardened and signed control software
        StructuralReinforcement, // engineering to withstand disasters
        DiversifiedSupply,   // multiple suppliers/materials sourcing
        PolicyHedging        // legal agreements and insurance coverage
    }

    struct Term {
        EnergyType  projectType;
        AttackType  risk;
        DefenseType mitigation;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        EnergyType    projectType,
        AttackType    risk,
        DefenseType   mitigation,
        uint256       timestamp
    );

    /**
     * @notice Register a new Renewable Energy term.
     * @param projectType The renewable energy project category.
     * @param risk        The anticipated risk/attack vector.
     * @param mitigation  The chosen defense/mitigation mechanism.
     * @return id         The ID of the newly registered term.
     */
    function registerTerm(
        EnergyType  projectType,
        AttackType  risk,
        DefenseType mitigation
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            projectType: projectType,
            risk:        risk,
            mitigation:  mitigation,
            timestamp:   block.timestamp
        });
        emit TermRegistered(id, projectType, risk, mitigation, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Renewable Energy term.
     * @param id The term ID.
     * @return projectType The renewable energy project category.
     * @return risk        The risk/attack vector.
     * @return mitigation  The defense/mitigation mechanism.
     * @return timestamp   When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            EnergyType  projectType,
            AttackType  risk,
            DefenseType mitigation,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.projectType, t.risk, t.mitigation, t.timestamp);
    }
}
