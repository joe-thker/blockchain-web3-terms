// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RingMinersRegistry
 * @notice Defines “Ring Miners” categories along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RingMinersRegistry {
    /// @notice Types of ring miner roles or operations
    enum RingMinerType {
        BlockProducer,       // mines or validates new blocks
        BlockRelayer,        // relays mined blocks across network
        FrontierSeeder,      // initializes new rings or shards
        ValidatorAggregator, // aggregates signatures for ring consensus
        StateChurner         // rotates ring members to preserve liveness
    }

    /// @notice Attack vectors targeting ring miner operations
    enum AttackType {
        EclipseAttack,       // isolate miners from honest peers
        Bribery,             // pay miners to include malicious blocks
        Collusion,           // coordinate dishonest mining to control ring
        DDoS,                // overload miner nodes with traffic
        ConsensusDelay       // withholding blocks to stall progress
    }

    /// @notice Defense mechanisms for securing ring miners
    enum DefenseType {
        RedundantPeers,      // connect to many independent peers
        MultiSigVerification,// require multiple miner signatures
        RandomizedRotation,  // shuffle ring members periodically
        RateLimiting,        // cap peer requests to prevent DDoS
        WatchtowerMonitoring // off-chain monitors to detect misbehavior
    }

    struct Term {
        RingMinerType minerType;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed   id,
        RingMinerType     minerType,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new Ring Miners term.
     * @param minerType The ring miner role or operation type.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        RingMinerType minerType,
        AttackType    attack,
        DefenseType   defense
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
     * @notice Retrieve details of a registered Ring Miners term.
     * @param id The term ID.
     * @return minerType The ring miner role or operation type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RingMinerType minerType,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.minerType, t.attack, t.defense, t.timestamp);
    }
}
