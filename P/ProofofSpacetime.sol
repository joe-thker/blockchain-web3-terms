// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfSpacetimeRegistry
 * @notice Defines “Proof-of-Spacetime” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ProofOfSpacetimeRegistry {
    /// @notice Variants of Proof-of-Spacetime (PoST) mechanisms
    enum PoSTType {
        ContinuousProof,      // continuous on-chain proofs over time
        ChallengeResponse,    // challenge–response based proofs
        SNARKBased,           // zk-SNARK proofs of storage+time
        WindowedProof,        // proofs over randomized time windows
        LambdaPoST            // Lambda-based Proof-of-Spacetime
    }

    /// @notice Attack vectors targeting PoST systems
    enum AttackType {
        DataDeletion,         // deleting stored data to avoid proof
        ProofForgery,         // fabricating proof responses
        SybilProofs,          // many fake nodes to overwhelm checks
        Collusion,            // cooperating to cheat challenge rounds
        DenialOfService       // flooding proof requests to disrupt service
    }

    /// @notice Defense mechanisms for securing PoST
    enum DefenseType {
        RandomChallenges,     // unpredictable proof challenges
        MerkleCommitments,    // merkle-root commitments of stored data
        StakeSlashing,        // slash stake on proof failures
        Redundancy,           // redundant storage across nodes
        RateLimiting          // throttle proof submissions per node
    }

    struct Term {
        PoSTType    postType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PoSTType    postType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Proof-of-Spacetime term.
     * @param postType The PoST mechanism variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PoSTType    postType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            postType:  postType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, postType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered PoST term.
     * @param id The term ID.
     * @return postType The PoST mechanism variant.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PoSTType    postType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.postType, t.attack, t.defense, t.timestamp);
    }
}
