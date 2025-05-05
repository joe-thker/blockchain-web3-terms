// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SelfishMiningRegistry
 * @notice Defines “Selfish Mining” attack variants along with common
 *         attack vectors (sub-variants) and defense mechanisms. Users can
 *         register and query these combinations on-chain for analysis or governance.
 */
contract SelfishMiningRegistry {
    /// @notice Variants of selfish mining strategies
    enum MiningType {
        Classic,           // withhold block until competitor finds one
        Stubborn,          // occasionally publish blocks to maximize gain
        Trail,             // selectively release based on lead length
        LeadStubborn,      // publish only when ahead by two or more
        SelectiveRelease   // hold and release only certain blocks
    }

    /// @notice Sub-attack vectors within selfish mining
    enum AttackType {
        BlockWithholding,  // miners refuse to broadcast blocks
        ForkTriggering,    // intentionally create private forks
        PartialRelease,    // release only some blocks to confuse honest miners
        BlockSuppression,  // attempt to orphan honest-mined blocks
        ChainSelectionBias // bias honest miners to choose attacker’s fork
    }

    /// @notice Defense mechanisms against selfish mining
    enum DefenseType {
        UniformTieBreaking,    // honest miners randomly choose among equal chains
        FreshBlockFirst,       // prefer newer blocks to discourage withholding
        DelayedRewards,        // delay block rewards to ensure validity
        BlockPublicationAudit, // on‐chain logging of block timestamps
        PenaltyForWithholding // slash or penalize detected withholding miners
    }

    struct Term {
        MiningType miningStrategy;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        MiningType   miningStrategy,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Selfish Mining term.
     * @param miningStrategy The selfish mining variant.
     * @param attack         The specific sub-attack vector.
     * @param defense        The chosen defense mechanism.
     * @return id            The ID of the newly registered term.
     */
    function registerTerm(
        MiningType   miningStrategy,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            miningStrategy: miningStrategy,
            attack:         attack,
            defense:        defense,
            timestamp:      block.timestamp
        });
        emit TermRegistered(id, miningStrategy, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Selfish Mining term.
     * @param id The term ID.
     * @return miningStrategy The selfish mining variant.
     * @return attack         The sub-attack vector.
     * @return defense        The defense mechanism.
     * @return timestamp      When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            MiningType   miningStrategy,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.miningStrategy, t.attack, t.defense, t.timestamp);
    }
}
