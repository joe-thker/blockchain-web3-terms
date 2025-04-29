// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfReplicationRegistry
 * @notice Defines “Proof-of-Replication” mechanisms along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ProofOfReplicationRegistry {
    /// @notice Variants of Proof-of-Replication schemes
    enum ReplicationType {
        SingleNode,        // replication on one storage node
        MultiNode,         // replication across multiple nodes
        ErasureCoding,     // data encoded with redundancy
        Sharded,           // data sharded and replicated
        CrossRegion        // replication across geographic regions
    }

    /// @notice Attack vectors targeting replication systems
    enum AttackType {
        DataLoss,          // node failure or data deletion
        DataTampering,     // unauthorized modification of replicas
        SybilReplication,  // fake nodes to subvert replication guarantee
        ProofForgery,      // forging replication proofs
        DenialOfService    // exhausting bandwidth/storage of nodes
    }

    /// @notice Defense mechanisms for replication integrity
    enum DefenseType {
        Redundancy,        // extra copies beyond minimum requirement
        CryptoProofs,      // on-chain verifiable replication proofs
        AuditTrails,       // logs of replication events and checks
        ReputationSystem,  // penalize misbehaving nodes
        IncentiveMechanism // rewards for honest replication
    }

    struct Term {
        ReplicationType replication;
        AttackType      attack;
        DefenseType     defense;
        uint256         timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ReplicationType replication,
        AttackType      attack,
        DefenseType     defense,
        uint256         timestamp
    );

    /**
     * @notice Register a new Proof-of-Replication term.
     * @param replication The replication scheme variant.
     * @param attack      The anticipated attack vector.
     * @param defense     The chosen defense mechanism.
     * @return id         The ID of the newly registered term.
     */
    function registerTerm(
        ReplicationType replication,
        AttackType      attack,
        DefenseType     defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            replication: replication,
            attack:      attack,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit TermRegistered(id, replication, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return replication The replication scheme variant.
     * @return attack      The attack vector.
     * @return defense     The defense mechanism.
     * @return timestamp   When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ReplicationType replication,
            AttackType      attack,
            DefenseType     defense,
            uint256         timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.replication, t.attack, t.defense, t.timestamp);
    }
}
