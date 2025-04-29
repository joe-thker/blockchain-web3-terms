// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfValidationRegistry
 * @notice Defines “Proof-of-Validation” categories along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ProofOfValidationRegistry {
    /// @notice Variants of Proof-of-Validation mechanisms
    enum ValidationType {
        SignatureCheck,       // cryptographic signature verification
        MerkleProof,          // Merkle tree inclusion proof
        ZKProof,              // zero-knowledge proof validation
        OracleAssertion,      // external oracle attestations
        ConsensusVote         // on-chain consensus vote validation
    }

    /// @notice Attack vectors targeting validation systems
    enum AttackType {
        ForgedSignature,      // submitting fake signatures
        InvalidProof,         // supplying incorrect Merkle/ZK proofs
        OracleSpoofing,       // feeding false data via compromised oracle
        ReplayAttack,         // replaying old valid proofs
        SybilVoting           // manipulating consensus via fake identities
    }

    /// @notice Defense mechanisms for Proof-of-Validation
    enum DefenseType {
        ReplayProtection,     // nonces or timestamps to prevent replays
        MultiSignature,       // require multiple independent signatures
        ProofAggregation,     // aggregate proofs from several sources
        OracleRedundancy,     // use multiple oracles for cross-checks
        RateLimiting          // throttle submissions to avoid spam
    }

    struct Term {
        ValidationType validation;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        ValidationType     validation,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Proof-of-Validation term.
     * @param validation The PoV mechanism variant.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        ValidationType validation,
        AttackType     attack,
        DefenseType    defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            validation: validation,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, validation, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Proof-of-Validation term.
     * @param id The term ID.
     * @return validation The PoV mechanism variant.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ValidationType validation,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.validation, t.attack, t.defense, t.timestamp);
    }
}
