// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OrphanedBlockRegistry
 * @notice Defines subtypes of orphaned blocks along with common
 *         attack vectors and defense mechanisms. Users can
 *         register and query these combinations on‑chain.
 */
contract OrphanedBlockRegistry {
    /// @notice Subtypes of orphaned blocks
    enum OrphanedBlockType {
        Stale,          // a valid block not built upon
        Uncle,          // Ethereum‑style uncle block
        Detached,       // block on a fork that didn’t become canonical
        Reorged,        // block replaced by a longer chain
        DeadEnd         // block at the tip of a dead fork
    }

    /// @notice Attack vectors causing or exploiting orphaned blocks
    enum AttackType {
        SelfishMining,      // miner withholds blocks to gain advantage
        EclipseAttack,      // isolating nodes on a stale chain
        Withholding,        // refusing to broadcast valid blocks
        NetworkPartition,   // splitting the network to create forks
        DoubleSpend         // exploiting fork to spend twice
    }

    /// @notice Defense mechanisms against orphaned‑block risks
    enum DefenseType {
        UncleInclusion,     // reward inclusion of uncles to reduce waste
        Checkpointing,      // enforce periodic finality points
        GHOSTProtocol,      // fork‑choice including uncle weight
        ConnectivityBoost,  // improved peer diversity and resilience
        FinalityGadget      // layer‑2 finality to finalize history
    }

    struct Term {
        OrphanedBlockType orphanType;
        AttackType        attack;
        DefenseType       defense;
        uint256           timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        OrphanedBlockType orphanType,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new orphaned‑block term.
     * @param orphanType The subtype of orphaned block.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the registered term.
     */
    function registerTerm(
        OrphanedBlockType orphanType,
        AttackType        attack,
        DefenseType       defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            orphanType: orphanType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, orphanType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return orphanType The orphaned‑block subtype.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OrphanedBlockType orphanType,
            AttackType        attack,
            DefenseType       defense,
            uint256           timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.orphanType, t.attack, t.defense, t.timestamp);
    }
}
