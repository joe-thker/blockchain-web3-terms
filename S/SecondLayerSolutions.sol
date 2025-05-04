// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SecondLayerSolutionsRegistry
 * @notice Defines “Second-Layer Solutions” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract SecondLayerSolutionsRegistry {
    /// @notice Types of second-layer (L2) solutions
    enum L2Type {
        OptimisticRollup,     // fraud-proof based rollup
        ZKRollup,             // validity-proof based rollup
        StateChannel,         // off-chain state channels
        Plasma,               // UTXO sidechain with checkpoints
        Sidechain             // sovereign chain pegged to L1
    }

    /// @notice Attack vectors targeting L2 solutions
    enum AttackType {
        DataAvailability,     // withholding or corrupting L2 data
        FraudProofDelay,      // delaying submission of fraud proofs
        SequencerCensorship,  // censoring transactions at sequencer
        BridgeExploit,        // attacking L1-L2 bridge contracts
        CollatorBribery       // bribing collators to include invalid state
    }

    /// @notice Defense mechanisms for securing L2 solutions
    enum DefenseType {
        DACommittee,          // decentralized data availability committee
        FastFraudProofs,      // rapid on-chain fraud proof verification
        MultiSequencer,       // multiple sequencers to prevent censorship
        AuditedBridges,       // third-party audits of bridge code
        OnchainFallback       // fallback to L1 execution for disputes
    }

    struct Term {
        L2Type      solution;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        L2Type       solution,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Second-Layer Solution term.
     * @param solution The L2 solution variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        L2Type      solution,
        AttackType  attack,
        DefenseType defense
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
     * @notice Retrieve details of a registered Second-Layer Solution term.
     * @param id The term ID.
     * @return solution  The L2 solution variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            L2Type      solution,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.solution, t.attack, t.defense, t.timestamp);
    }
}
