// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfImmutabilityRegistry
 * @notice Defines “Proof-of-Immutability (PoIM)” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ProofOfImmutabilityRegistry {
    /// @notice Variants of PoIM mechanisms
    enum PoIMType {
        BlockchainAnchoring,    // anchoring state in another chain
        TimestampingService,    // use a trusted timestamp authority
        MerkleProofAnchoring,   // embed Merkle root in on-chain data
        CrossChainAnchor,       // anchor proofs across multiple chains
        DecentralizedOracle     // use multiple oracle attestations
    }

    /// @notice Attack vectors targeting immutability proofs
    enum AttackType {
        ProofRollback,          // reverting to a prior state
        AnchorSpoofing,         // submitting fake anchor proofs
        TimestampManipulation,  // forging or delaying timestamps
        OracleCompromise,       // corrupting oracle attestation
        Collusion               // colluding to re-anchor incorrect data
    }

    /// @notice Defense mechanisms for securing immutability proofs
    enum DefenseType {
        MultiChainVerification, // verify anchors on multiple chains
        DecentralizedOracles,   // aggregate many oracle sources
        NonceTracking,          // ensure each proof is unique
        OnChainAudits,          // regular audit of proof logs
        CircuitBreaker          // pause acceptance on suspicious feeds
    }

    struct Term {
        PoIMType    pomType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PoIMType    pomType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Proof-of-Immutability term.
     * @param pomType  The PoIM mechanism variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PoIMType    pomType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            pomType:   pomType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, pomType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Proof-of-Immutability term.
     * @param id The term ID.
     * @return pomType   The PoIM mechanism variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PoIMType    pomType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.pomType, t.attack, t.defense, t.timestamp);
    }
}
