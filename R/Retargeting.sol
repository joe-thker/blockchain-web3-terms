// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RetargetingRegistry
 * @notice Defines “Retargeting” difficulty adjustment algorithms along with common
 *         attack vectors and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract RetargetingRegistry {
    /// @notice Types of retargeting (difficulty adjustment) algorithms
    enum RetargetType {
        Bitcoin,            // every 2016 blocks adjust by time ratio
        DarkGravityWave,    // per-block adjustment with weighted average
        KimotoGravityWell,  // multi-window weighted adjustment
        DigiShield,         // per-block LWMA-based adjustment
        LinearWeightedAverage // simplified LWMA over N blocks
    }

    /// @notice Attack vectors targeting retargeting
    enum AttackType {
        TimeWarp,           // manipulating block timestamps for gain
        DifficultyBomb,     // delaying blocks to shift difficulty
        TimestampManipulation, // false timestamp reports by miners
        ChainSplit,         // fork to different difficulty schedules
        BlockWithholding    // withholding solved blocks to control difficulty
    }

    /// @notice Defense mechanisms for securing difficulty adjustment
    enum DefenseType {
        TimestampBounds,    // enforce max drift on block timestamps
        MedianTimePast,     // use MTP rather than raw timestamp
        DifficultyLimits,   // cap adjustment per period
        MultiWindowAverage, // use multiple windows to smooth data
        ConsensusRuleHardfork // upgrade rules to fix exploits
    }

    struct Term {
        RetargetType retargetAlgo;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RetargetType      retargetAlgo,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new Retargeting term.
     * @param retargetAlgo The retargeting algorithm type.
     * @param attack       The anticipated attack vector.
     * @param defense      The chosen defense mechanism.
     * @return id          The ID of the newly registered term.
     */
    function registerTerm(
        RetargetType retargetAlgo,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            retargetAlgo: retargetAlgo,
            attack:       attack,
            defense:      defense,
            timestamp:    block.timestamp
        });
        emit TermRegistered(id, retargetAlgo, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Retargeting term.
     * @param id The term ID.
     * @return retargetAlgo The retargeting algorithm type.
     * @return attack       The attack vector.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RetargetType retargetAlgo,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.retargetAlgo, t.attack, t.defense, t.timestamp);
    }
}
