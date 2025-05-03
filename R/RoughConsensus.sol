// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RoughConsensusRegistry
 * @notice Defines “Rough Consensus” decision–making styles along with common
 *         attack vectors (risks) and mitigation mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RoughConsensusRegistry {
    /// @notice Styles or forms of rough consensus
    enum ConsensusStyle {
        BellCurve,          // majority around the middle position
        LazyConsensus,      // assume agreement unless objection raised
        ExplicitPoll,       // light-weight on-chain poll or signaling
        InformalRound,      // iterative discussion rounds off-chain
        FastTrack           // rapid approval with short objection window
    }

    /// @notice Risks or attack vectors against consensus process
    enum AttackType {
        Censorship,         // suppressing dissenting voices or objections
        SybilInfluence,     // fake participants skewing feedback
        RogueMiners,        // block producers censor or re-order votes
        SpamObjections,     // flooding with frivolous objections
        CoordinatedPush     // collusion to force a particular outcome
    }

    /// @notice Mitigations or defenses for consensus integrity
    enum DefenseType {
        OpenParticipation,  // allow anyone to raise objections
        IdentityChecks,     // verify participants via on-chain identity
        TimeBoundRounds,    // fixed windows for objections/discussion
        QuorumRequirement,  // require minimum turnout for validity
        ObjectionFiltering  // on-chain filter to remove spam objections
    }

    struct Term {
        ConsensusStyle style;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed  id,
        ConsensusStyle   style,
        AttackType       attack,
        DefenseType      defense,
        uint256          timestamp
    );

    /**
     * @notice Register a new Rough Consensus term.
     * @param style    The rough consensus style variant.
     * @param attack   The anticipated risk or attack vector.
     * @param defense  The chosen mitigation mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        ConsensusStyle style,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            style:     style,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, style, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Rough Consensus term.
     * @param id The term ID.
     * @return style      The consensus style variant.
     * @return attack     The risk or attack vector.
     * @return defense    The mitigation mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ConsensusStyle style,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.style, t.attack, t.defense, t.timestamp);
    }
}
