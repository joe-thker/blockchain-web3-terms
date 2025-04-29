// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfDeveloperRegistry
 * @notice Defines “Proof-of-Developer (PoD)” verification categories along with
 *         common attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ProofOfDeveloperRegistry {
    /// @notice Variants of Proof-of-Developer mechanisms
    enum PoDType {
        VerifiedCommit,         // signed commit on official repo
        CodeReviewApproval,     // approved pull request by maintainer
        MaintainerSignature,    // signature from project maintainer
        ContributorNFT,         // NFT minted for contributions
        BountyCompletion        // completed bounty tasks verification
    }

    /// @notice Attack vectors targeting developer proofs
    enum AttackType {
        Impersonation,          // fake identity to submit commits
        FakeReviews,            // collusive or bogus code reviews
        KeyCompromise,          // stolen maintainer keys
        SpoofedSignatures,      // forged digital signatures
        SybilContribution       // many fake accounts to game bounties
    }

    /// @notice Defense mechanisms for securing developer proofs
    enum DefenseType {
        GitHubOAuth,            // OAuth-backed commit verification
        MultiSigCommits,        // require multiple maintainer sigs
        OnChainGovernance,      // community vote on proof validity
        ReputationScoring,      // weight proofs by contributor reputation
        AuditTrail              // immutable logging of proof events
    }

    struct Term {
        PoDType    podType;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PoDType    podType,
        AttackType attack,
        DefenseType defense,
        uint256    timestamp
    );

    /**
     * @notice Register a new Proof-of-Developer term.
     * @param podType  The PoD mechanism variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PoDType     podType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            podType:   podType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, podType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered PoD term.
     * @param id The term ID.
     * @return podType   The PoD mechanism variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PoDType     podType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.podType, t.attack, t.defense, t.timestamp);
    }
}
