// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PostMineRegistry
 * @notice Defines “Post-Mine” allocation categories along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract PostMineRegistry {
    /// @notice Types of post-mine allocations or mechanisms
    enum PostMineType {
        DeveloperVesting,     // tokens vested to developers after launch
        TreasuryAllocation,   // treasury funds allocated post-genesis
        CommunityIncentives,  // airdrops or rewards after mainnet
        BugBountyProgram,     // allocations for security bounties
        FutureTokenSale       // tokens reserved for later sale rounds
    }

    /// @notice Attack vectors targeting post-mine allocations
    enum AttackType {
        RugPull,              // developers drain allocated tokens
        MaliciousMinting,     // unauthorized token issuance
        GovernanceTakeover,   // capturing governance to redirect funds
        InsiderDump,          // insiders dumping tokens on market
        InflationSpike        // sudden high inflation harming price
    }

    /// @notice Defense mechanisms for post-mine schemes
    enum DefenseType {
        VestingSchedule,      // time-locked vesting for allocations
        MultiSigTreasury,     // multi-signature control over funds
        OnChainGovernance,    // community votes for allocation changes
        EmissionCap,          // maximum emission limits enforced
        TransparencyReports   // regular on-chain reporting of spend
    }

    struct Term {
        PostMineType  postMineType;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PostMineType  postMineType,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Post-Mine term.
     * @param postMineType The post-mine allocation category.
     * @param attack       The anticipated attack vector.
     * @param defense      The chosen defense mechanism.
     * @return id          The ID of the newly registered term.
     */
    function registerTerm(
        PostMineType postMineType,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            postMineType: postMineType,
            attack:       attack,
            defense:      defense,
            timestamp:    block.timestamp
        });
        emit TermRegistered(id, postMineType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Post-Mine term.
     * @param id The term ID.
     * @return postMineType The post-mine allocation category.
     * @return attack       The attack vector.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PostMineType postMineType,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.postMineType, t.attack, t.defense, t.timestamp);
    }
}
