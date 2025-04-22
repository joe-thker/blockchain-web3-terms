// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OrphanRegistry
 * @notice Defines “Orphan” categories (e.g., stale or uncle blocks),
 *         common attack vectors that can cause or exploit orphaning,
 *         and defense mechanisms to mitigate orphan‑related risks.
 *         Users can register and query these combinations on‑chain.
 */
contract OrphanRegistry {
    /// @notice Types of orphaned blocks/transactions
    enum OrphanType {
        StaleBlock,          // a valid block not built upon
        UncleBlock,          // Ethereum‑style “uncle” block
        OrphanTransaction,   // tx dropped due to chain reorg
        DetachedChain,       // branch that never reorged into main
        ChainSplit           // temporary fork before resolution
    }

    /// @notice Attack vectors leading to orphan creation or exploitation
    enum AttackType {
        SelfishMining,       // withholding blocks to gain advantage
        EclipseAttack,       // isolating a node to feed stale chain
        BlockWithholding,    // miner refuses to broadcast block
        NetworkPartition,    // split network causes parallel forks
        _51PercentAttack    // double‑spend via majority control
    }

    /// @notice Defense mechanisms against orphan risks
    enum DefenseType {
        UncleInclusion,      // reward inclusion of uncles to reduce waste
        Checkpointing,       // fixed points to ignore older forks
        GHOSTProtocol,       // fork‑choice favoring more work including uncles
        ImprovedConnectivity,// diversify peer connections
        FinalityGadget       // enforce irreversible finality (e.g. LMD‑GHOST + Casper)
    }

    struct OrphanTerm {
        OrphanType   orphan;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => OrphanTerm) public terms;

    event OrphanTermRegistered(
        uint256 indexed id,
        OrphanType   orphan,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Orphan term.
     * @param orphan  The orphan category.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the registered term.
     */
    function registerTerm(
        OrphanType  orphan,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = OrphanTerm({
            orphan:    orphan,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit OrphanTermRegistered(id, orphan, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Orphan term.
     * @param id The term ID.
     * @return orphan   The orphan category.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OrphanType   orphan,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        OrphanTerm storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.orphan, t.attack, t.defense, t.timestamp);
    }
}
