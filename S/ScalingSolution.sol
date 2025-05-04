// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScalingSolutionRegistry
 * @notice Defines “Scaling Solution” categories along with common
 *         attack vectors (risks) and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ScalingSolutionRegistry {
    /// @notice Types of scaling solutions
    enum SolutionType {
        Layer2Rollup,       // rollups like Optimistic or zk-rollups
        Sharding,           // state and transaction sharding
        StateChannels,      // off-chain channels for fast Tx
        Sidechain,          // independent chain pegged to mainnet
        Hybrid              // combination of multiple approaches
    }

    /// @notice Attack vectors targeting scaling solutions
    enum AttackType {
        DataAvailability,   // withholding or corrupting data
        FraudProofDelay,    // delaying fraud proofs on rollups
        CollatorCensorship, // censoring txs at shard/rollup collators
        BridgeExploit,      // attacking cross-chain bridges
        StateChannelHijack  // taking over or freezing channels
    }

    /// @notice Defense mechanisms for robust scaling solutions
    enum DefenseType {
        MultiDACommittee,   // decentralized data availability committees
        FastChallenge,      // rapid on-chain challenges for fraud proofs
        SequencerFallback,  // fallback to L1 sequencer if collator fails
        AuditedBridges,     // third-party audits of bridge contracts
        ChannelTimeouts     // enforce timeouts on state channel updates
    }

    struct Term {
        SolutionType solution;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed   id,
        SolutionType      solution,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new Scaling Solution term.
     * @param solution The scaling solution category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        SolutionType solution,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            solution:  solution,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, solution, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Scaling Solution term.
     * @param id The term ID.
     * @return solution  The scaling solution category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            SolutionType solution,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.solution, t.attack, t.defense, t.timestamp);
    }
}
