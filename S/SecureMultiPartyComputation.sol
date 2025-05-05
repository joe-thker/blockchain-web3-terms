// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SecureMPCRegistry
 * @notice Defines “Secure Multi-Party Computation (sMPC)” variants along with common
 *         attack vectors and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract SecureMPCRegistry {
    /// @notice Variants of secure MPC protocols
    enum MPCType {
        ShamirSecretSharing,    // classic threshold secret sharing
        SPDZ,                   // share–multiply–decrypt protocol
        GMW,                    // Garbled circuits based MPC
        BGW,                    // Ben-Or, Goldwasser, Wigderson protocol
        HoneyBadgerMPC          // asynchronous MPC for Byzantine faults
    }

    /// @notice Attack vectors against MPC sessions
    enum AttackType {
        ShareLeakage,           // leaking individual secret shares
        Collusion,              // subset of parties colluding to reconstruct secret
        MaliciousInput,         // parties providing incorrect inputs
        CommunicationCutoff,    // network disruption between participants
        SideChannel             // timing or power analysis on participants
    }

    /// @notice Defense mechanisms for secure MPC
    enum DefenseType {
        VerifiableSSS,          // use verifiable secret sharing to detect bad shares
        CommitReveal,           // commit-then-reveal to prevent input tampering
        BroadcastChannel,       // reliable broadcast for messages integrity
        ThresholdAudit,         // on-chain audits of subset of shares
        ZeroKnowledgeProofs     // ZK proofs of correct local computation
    }

    struct Term {
        MPCType     protocol;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        MPCType      protocol,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new sMPC term.
     * @param protocol The secure MPC protocol variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        MPCType     protocol,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            protocol:  protocol,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, protocol, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered sMPC term.
     * @param id The term ID.
     * @return protocol  The secure MPC protocol variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            MPCType     protocol,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.protocol, t.attack, t.defense, t.timestamp);
    }
}
