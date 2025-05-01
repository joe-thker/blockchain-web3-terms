// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RedundancyRegistry
 * @notice Defines “Redundancy” categories along with common
 *         failure/attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RedundancyRegistry {
    /// @notice Types of redundancy implementations
    enum RedundancyType {
        DataRedundancy,        // duplicate data storage (e.g., RAID, IPFS replication)
        GeographicRedundancy,  // distributed nodes across regions
        PowerRedundancy,       // backup power supplies (UPS, generators)
        NetworkPathRedundancy, // multiple network routes/connectivity
        HardwareRedundancy     // spare hardware components hot-standby
    }

    /// @notice Failure/attack vectors against redundant systems
    enum AttackType {
        SinglePointFailure,    // unreplicated component failure
        PartitionAttack,       // network split to isolate replicas
        DataCorruption,        // corrupted data propagating across replicas
        ResourceExhaustion,    // exhausting capacity of backup systems
        Tampering              // unauthorized modification of backups
    }

    /// @notice Defense mechanisms for robust redundancy
    enum DefenseType {
        MultiReplication,      // maintain >2 copies across independent nodes
        Checksums,             // verify data integrity with hashes
        ErasureCoding,         // encode with Reed-Solomon for recovery
        HotStandby,            // automatic failover to live backups
        RegularAudits          // periodic validation and repair of replicas
    }

    struct Term {
        RedundancyType redundancyType;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        RedundancyType     redundancyType,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Redundancy term.
     * @param redundancyType The redundancy implementation category.
     * @param attack         The anticipated failure/attack vector.
     * @param defense        The chosen defense mechanism.
     * @return id            The ID of the newly registered term.
     */
    function registerTerm(
        RedundancyType redundancyType,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            redundancyType: redundancyType,
            attack:         attack,
            defense:        defense,
            timestamp:      block.timestamp
        });
        emit TermRegistered(id, redundancyType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Redundancy term.
     * @param id The term ID.
     * @return redundancyType The redundancy implementation category.
     * @return attack         The failure/attack vector.
     * @return defense        The defense mechanism.
     * @return timestamp      When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RedundancyType redundancyType,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.redundancyType, t.attack, t.defense, t.timestamp);
    }
}
