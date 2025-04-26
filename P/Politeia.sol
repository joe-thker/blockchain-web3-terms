// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PoliteiaRegistry
 * @notice Defines “Politeia” proposal categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PoliteiaRegistry {
    /// @notice Categories of Politeia proposals
    enum PoliteiaType {
        GovernanceProposal,    // changes to protocol rules
        BudgetProposal,        // allocate treasury funds
        TechnicalProposal,     // software/technical enhancements
        CommunityProposal,     // community-driven initiatives
        PolicyProposal         // updates to policies or bylaws
    }

    /// @notice Attack vectors targeting Politeia governance
    enum AttackType {
        SybilAttack,           // creating many fake identities
        VoteBribery,           // bribing stakeholders to vote
        Censorship,            // blocking or delaying proposals
        SpamProposal,          // flooding with low-quality proposals
        DoubleVoting           // voting multiple times with one stake
    }

    /// @notice Defense mechanisms for Politeia governance
    enum DefenseType {
        StakeRequirement,      // require deposit/stake to propose/vote
        IdentityVerification,  // require KYC or unique registration
        QuorumRequirement,     // enforce minimum vote threshold
        RateLimiting,          // limit proposals per time period
        CommunityModeration    // off-chain review before on-chain voting
    }

    struct Term {
        PoliteiaType politeiaType;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PoliteiaType politeiaType,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Politeia term.
     * @param politeiaType The category of the proposal.
     * @param attack       The anticipated attack vector.
     * @param defense      The chosen defense mechanism.
     * @return id          The ID of the newly registered term.
     */
    function registerTerm(
        PoliteiaType politeiaType,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            politeiaType: politeiaType,
            attack:       attack,
            defense:      defense,
            timestamp:    block.timestamp
        });
        emit TermRegistered(id, politeiaType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Politeia term.
     * @param id The term ID.
     * @return politeiaType The proposal category.
     * @return attack       The attack vector.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PoliteiaType politeiaType,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.politeiaType, t.attack, t.defense, t.timestamp);
    }
}
