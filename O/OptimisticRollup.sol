// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OptimisticRollupRegistry
 * @notice Defines types, attack vectors, and defense mechanisms for
 *         Optimistic Rollup solutions. Users can register and query
 *         these combinations on‑chain for documentation or governance.
 */
contract OptimisticRollupRegistry {
    /// @notice Supported Optimistic Rollup implementations
    enum RollupType {
        Optimism,           // the OP Rollup by Optimism
        Arbitrum,           // the Arbitrum Rollup by Offchain Labs
        Base,               // the Base Rollup by Coinbase
        Boba,               // the Boba Network Rollup
        Custom              // any other rollup type
    }

    /// @notice Common attack vectors against rollups
    enum AttackType {
        SequencerCensorship,    // sequencer refuses to include txs
        DataWithholding,        // rollup node withholds state data
        FraudulentStateProof,   // submission of an invalid state root
        ChallengeDelay,         // timeout in challenge window exploited
        BridgeExploit           // vulnerability in cross‑chain bridge
    }

    /// @notice Defense mechanisms rollups employ
    enum DefenseType {
        FraudProof,             // on‑chain fraud proof system
        Watchtower,             // off‑chain watchers alert on misbehavior
        ForcedInclusion,        // mechanism to force tx inclusion
        DataAvailability,       // on‑chain DA commitments
        EmergencyExit           // user exit via L1 in emergencies
    }

    struct RollupTerm {
        RollupType  rollup;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => RollupTerm) public terms;

    event RollupTermRegistered(
        uint256 indexed id,
        RollupType  rollup,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Optimistic Rollup term.
     * @param rollup  The rollup implementation type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the registered term.
     */
    function registerTerm(
        RollupType  rollup,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = RollupTerm({
            rollup:    rollup,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit RollupTermRegistered(id, rollup, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return rollup   The rollup implementation.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RollupType  rollup,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        RollupTerm storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.rollup, t.attack, t.defense, t.timestamp);
    }
}
