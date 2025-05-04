// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScalingProblemRegistry
 * @notice Defines “Scaling Problem” categories along with common
 *         attack vectors (risks) and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ScalingProblemRegistry {
    /// @notice Types of blockchain scaling challenges
    enum ScalingType {
        ThroughputLimit,    // insufficient TPS for demand
        HighLatency,        // slow block confirmation times
        StateBloat,         // excessive state growth
        StorageConstraints, // node storage requirements too large
        ConsensusBottleneck // consensus slows down under load
    }

    /// @notice Attack vectors exploiting scaling weaknesses
    enum AttackType {
        SpamTransactions,   // flooding network with low-value txs
        DDoS,               // denial-of-service on validators
        StateExhaustion,    // forcing state to grow rapidly
        GasPriceManipulation, // inflating gas prices to block usage
        PartitionAttack     // splitting network to worsen latency
    }

    /// @notice Defense mechanisms to mitigate scaling issues
    enum DefenseType {
        Layer2Rollups,      // offload transactions to rollup chains
        Sharding,           // split state and txs across shards
        StateRent,          // rent-based state cleanup
        AdaptiveBlockSize,  // dynamically adjust block size/gas limit
        Compression         // compress state and transaction data
    }

    struct Term {
        ScalingType scaleIssue;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ScalingType    scaleIssue,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new Scaling Problem term.
     * @param scaleIssue The scaling challenge category.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        ScalingType scaleIssue,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            scaleIssue: scaleIssue,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, scaleIssue, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Scaling Problem term.
     * @param id The term ID.
     * @return scaleIssue The scaling challenge category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ScalingType scaleIssue,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.scaleIssue, t.attack, t.defense, t.timestamp);
    }
}
