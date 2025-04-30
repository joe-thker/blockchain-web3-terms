// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuorumRegistry
 * @notice Defines “Quorum (Governance)” models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract QuorumRegistry {
    /// @notice Types of governance quorums
    enum QuorumType {
        SimpleMajority,       // >50% of voting power
        SuperMajority,        // e.g., >66% or >75%
        Unanimous,            // 100% agreement required
        Plurality,            // most votes wins regardless of total
        FixedThreshold        // fixed number of votes required
    }

    /// @notice Attack vectors against quorum processes
    enum AttackType {
        LowParticipation,     // insufficient turnout to reach quorum
        VoteBrigading,        // coordinated voting to sway outcomes
        SybilAttack,          // fake identities to inflate turnout
        VoterBuyout,          // purchasing votes to meet quorum
        ProposalSpam          // flooding governance with proposals
    }

    /// @notice Defense mechanisms for securing quorum
    enum DefenseType {
        QuorumThresholdEnforcement, // enforce minimum turnout
        IdentityVerification,       // KYC/Onchain identity checks
        RateLimitProposals,         // cap proposals per period
        GovernanceTimelock,         // delay execution for review
        VoteEscrow                  // lock tokens to prove commitment
    }

    struct Term {
        QuorumType  quorum;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        QuorumType  quorum,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Quorum term.
     * @param quorum   The quorum model type.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        QuorumType  quorum,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            quorum:    quorum,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, quorum, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Quorum term.
     * @param id    The term ID.
     * @return quorum    The quorum model type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            QuorumType  quorum,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.quorum, t.attack, t.defense, t.timestamp);
    }
}
