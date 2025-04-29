// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfWorkRegistry
 * @notice Defines “Proof-of-Work (PoW)” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ProofOfWorkRegistry {
    /// @notice Variants of Proof-of-Work algorithms
    enum PoWType {
        SHA256,            // Bitcoin’s SHA-256 PoW
        Ethash,            // Ethereum’s Ethash PoW
        Scrypt,            // Litecoin’s Scrypt PoW
        Equihash,          // Zcash’s Equihash PoW
        CuckooCycle        // Cuckoo Cycle PoW (e.g., Grin)
    }

    /// @notice Attack vectors targeting PoW networks
    enum AttackType {
        FiftyOnePercent,   // >51% hashpower majority attack
        SelfishMining,     // withholding blocks to gain advantage
        BlockWithholding,  // miners hide found blocks
        DoubleSpending,    // reversing transactions by forking
        Timejacking        // manipulating timestamps to skew difficulty
    }

    /// @notice Defense mechanisms for PoW security
    enum DefenseType {
        Checkpointing,        // hard-coded checkpoints to prevent deep reorgs
        DifficultyAdjustment, // rapid retargeting to dampen timestamp attacks
        UncleInclusion,       // include stale blocks to reward honest miners
        PeerMonitoring,       // detect abnormal fork or timestamp behavior
        EconomicPenalties     // slash deposits for protocol-enforced stake
    }

    struct Term {
        PoWType     powType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PoWType     powType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Proof-of-Work term.
     * @param powType  The PoW algorithm variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PoWType     powType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            powType:   powType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, powType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered PoW term.
     * @param id The term ID.
     * @return powType   The PoW algorithm variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PoWType     powType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.powType, t.attack, t.defense, t.timestamp);
    }
}
