// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RebaseRegistry
 * @notice Defines “Rebase” mechanism variants along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RebaseRegistry {
    /// @notice Variants of rebasing mechanisms
    enum RebaseType {
        ElasticSupply,           // adjust total supply proportionally
        AlgorithmicRebase,       // rule‐based supply adjustment
        ProportionalDistribution,// distribute gains/losses pro rata
        Expansionary,            // increase supply on positive signal
        Contractionary           // decrease supply on negative signal
    }

    /// @notice Attack vectors targeting rebasing tokens
    enum AttackType {
        OracleManipulation,      // feeding wrong price oracles to trigger rebase
        FrontRunning,            // sandwiching rebase transactions
        SupplyShock,             // abnormal supply changes to destabilize market
        SmartContractExploit,    // exploiting flawed rebase logic
        GovernanceTakeover       // malicious upgrade or param change
    }

    /// @notice Defense mechanisms for securing rebasing
    enum DefenseType {
        MultiOracleFeeds,        // aggregate multiple oracles for price
        TWAPOracle,              // use time‐weighted average price
        CircuitBreaker,          // pause rebase on abnormal conditions
        RateLimiting,            // limit rebase frequency/magnitude
        GovernanceSafeguard      // timelocks and multisig for param changes
    }

    struct Term {
        RebaseType  rebaseType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RebaseType  rebaseType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Rebase term.
     * @param rebaseType The rebase mechanism variant.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        RebaseType  rebaseType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            rebaseType: rebaseType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, rebaseType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Rebase term.
     * @param id The term ID.
     * @return rebaseType The rebase mechanism variant.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RebaseType  rebaseType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.rebaseType, t.attack, t.defense, t.timestamp);
    }
}
