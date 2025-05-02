// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RepairMinersRegistry
 * @notice Defines “Repair Miners” categories along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RepairMinersRegistry {
    /// @notice Types of repair miner operations
    enum RepairMinerType {
        OnSiteMaintenance,   // physical repair at miner location
        FirmwareUpdate,      // remote firmware patching
        ModuleReplacement,   // swapping faulty hardware modules
        PreventiveCheck,     // routine performance inspections
        EmergencyRecovery    // rapid response after failure
    }

    /// @notice Attack vectors targeting repair miner processes
    enum AttackType {
        Tampering,           // unauthorized physical interference
        CounterfeitParts,    // installing fake or substandard components
        SupplyChainHijack,   // interception of parts in transit
        FirmwareExploit,     // injecting malicious firmware
        InsiderSabotage      // malicious actions by trusted personnel
    }

    /// @notice Defense mechanisms for securing repair operations
    enum DefenseType {
        AccessControl,       // restrict repair access to authorized staff
        PartCertification,   // verify authenticity of replacement parts
        SecureTransport,     // tracked and encrypted part delivery
        SignedFirmware,      // cryptographically signed update packages
        AuditLogging         // immutable on-chain repair logs
    }

    struct Term {
        RepairMinerType minerType;
        AttackType      attack;
        DefenseType     defense;
        uint256         timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        RepairMinerType    minerType,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Repair Miners term.
     * @param minerType The type of repair miner operation.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        RepairMinerType minerType,
        AttackType      attack,
        DefenseType     defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            minerType: minerType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, minerType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Repair Miners term.
     * @param id The term ID.
     * @return minerType The repair miner operation type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RepairMinerType minerType,
            AttackType      attack,
            DefenseType     defense,
            uint256         timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.minerType, t.attack, t.defense, t.timestamp);
    }
}
