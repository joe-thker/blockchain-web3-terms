// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProtocolLayerRegistry
 * @notice Defines “Protocol Layer” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ProtocolLayerRegistry {
    /// @notice Types of protocol layers
    enum LayerType {
        Layer0,                // underlying network/consensus infrastructure
        SettlementLayer,       // base ledger for settling transactions
        ScalabilityLayer,      // rollups, sidechains, or sharding solutions
        ApplicationLayer,      // smart contracts and dApps
        InteroperabilityLayer  // cross-chain/messaging protocols
    }

    /// @notice Attack vectors targeting protocol layers
    enum AttackType {
        ConsensusAttack,       // attacking the consensus mechanism
        SmartContractExploit,  // exploiting bugs in layer code
        BridgeExploit,         // attacking cross-chain bridges
        NetworkPartition,      // isolating nodes to cause forks
        MEVFrontRunning        // including/excluding txs for profit
    }

    /// @notice Defense mechanisms for protocol layers
    enum DefenseType {
        FormalVerification,    // mathematically verify critical logic
        MultiSigGovernance,    // require multisig for upgrades
        WatchtowerMonitoring,  // off-chain services to watch for faults
        RedundantValidators,   // many independent validators/nodes
        CrossChainAudits       // on-chain proofs/audits of bridge state
    }

    struct Term {
        LayerType   layer;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        LayerType   layer,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Protocol Layer term.
     * @param layer    The protocol layer category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        LayerType   layer,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            layer:     layer,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, layer, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Protocol Layer term.
     * @param id The term ID.
     * @return layer     The protocol layer category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            LayerType   layer,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.layer, t.attack, t.defense, t.timestamp);
    }
}
