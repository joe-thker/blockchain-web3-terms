// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ResistanceRegistry
 * @notice Defines “Resistance” categories along with common
 *         challenge vectors (attack) and countermeasures (defense).
 *         Users can register and query these combinations on-chain for analysis or governance.
 */
contract ResistanceRegistry {
    /// @notice Types of resistance mechanisms
    enum ResistanceType {
        CensorshipResistance,  // ability to resist content blocking
        SybilResistance,       // ability to resist fake identity attacks
        QuantumResistance,     // cryptographic resistance to quantum attacks
        FaultTolerance,        // system resilience to node failures
        CensorshipEvasion      // methods to bypass censorship (e.g., Tor)
    }

    /// @notice Attack vectors challenging resistance
    enum AttackType {
        NetworkCensorship,     // ISPs or governments blocking traffic
        SybilAttack,           // flooding network with fake nodes
        QuantumBreak,          // using quantum computers to break crypto
        PartitionAttack,       // splitting network to isolate nodes
        TrafficAnalysis        // de-anonymizing users via metadata
    }

    /// @notice Defense mechanisms strengthening resistance
    enum DefenseType {
        DecentralizedTopology, // fully peer-to-peer network design
        IdentityProofs,        // Web-of-trust or stake-based identity systems
        PostQuantumCrypto,     // lattice-based or hash-based signatures
        AdaptiveRouting,       // dynamic path selection to avoid partitions
        OnionRouting          // layered encryption for anonymity
    }

    struct Term {
        ResistanceType resistance;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        ResistanceType     resistance,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Resistance term.
     * @param resistance The resistance mechanism type.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        ResistanceType resistance,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            resistance: resistance,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, resistance, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Resistance term.
     * @param id The term ID.
     * @return resistance The resistance mechanism type.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ResistanceType resistance,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.resistance, t.attack, t.defense, t.timestamp);
    }
}
