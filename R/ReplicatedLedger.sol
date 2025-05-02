// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReplicatedLedgerRegistry
 * @notice Defines “Replicated Ledger” models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ReplicatedLedgerRegistry {
    /// @notice Types of replication models
    enum LedgerType {
        FullReplication,       // every node holds complete copy
        PartialReplication,    // nodes hold subsets of data
        ShardedReplication,    // data split across shards
        AuditLogReplication,   // append-only audit log copies
        MultiChainReplication  // cross-chain mirrored ledgers
    }

    /// @notice Attack vectors targeting replicated ledgers
    enum AttackType {
        DataInconsistency,     // replicas diverge due to sync issues
        Tampering,             // unauthorized modification of a copy
        DenialOfService,       // flooding nodes to prevent sync
        DataCorruption,        // corrupting data during replication
        UnauthorizedAccess     // illicit access to replica nodes
    }

    /// @notice Defense mechanisms for replicated ledgers
    enum DefenseType {
        ConsensusFinality,     // require finality proofs before sync
        CryptographicHashing,  // verify block hashes on each replica
        RedundancyChecks,      // cross-compare multiple replicas
        PermissionedAccess,    // restrict who can write/replicate
        IntegrityAudits        // periodic on-chain audit attestations
    }

    struct Term {
        LedgerType  ledgerType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        LedgerType    ledgerType,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Replicated Ledger term.
     * @param ledgerType The replication model.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        LedgerType  ledgerType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            ledgerType: ledgerType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, ledgerType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Replicated Ledger term.
     * @param id The term ID.
     * @return ledgerType The replication model.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            LedgerType  ledgerType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.ledgerType, t.attack, t.defense, t.timestamp);
    }
}
