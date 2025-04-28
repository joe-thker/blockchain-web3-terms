// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofMarketRegistry
 * @notice Defines “Proof Market” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ProofMarketRegistry {
    /// @notice Types of proof market models
    enum ProofMarketType {
        ZKProofExchange,      // trading of zero-knowledge proofs
        DataAvailability,     // markets for data availability proofs
        OracleProofs,         // proof provisioning by oracles
        StakingProofs,        // staking-based proof services
        ReputationProofs      // proof-of-reputation attestations
    }

    /// @notice Attack vectors targeting proof markets
    enum AttackType {
        ProofFabrication,     // creation of invalid proofs
        Collusion,            // colluding to push false proofs
        SybilAttack,          // many identities to dilute honest proofs
        ReplayAttack,         // reuse of old valid proofs
        DenialOfService       // spamming to overwhelm proof verifiers
    }

    /// @notice Defense mechanisms for proof markets
    enum DefenseType {
        zkVerification,       // on-chain zero-knowledge verification
        MultiPartyCheck,      // multi-party validation of proofs
        StakeSlashing,        // slashing misbehaving proof providers
        ReputationSystem,     // track and reward honest providers
        RateLimiting          // throttle proof submissions
    }

    struct Term {
        ProofMarketType marketType;
        AttackType      attack;
        DefenseType     defense;
        uint256         timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ProofMarketType marketType,
        AttackType      attack,
        DefenseType     defense,
        uint256         timestamp
    );

    /**
     * @notice Register a new Proof Market term.
     * @param marketType The proof market model category.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        ProofMarketType marketType,
        AttackType      attack,
        DefenseType     defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            marketType: marketType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, marketType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Proof Market term.
     * @param id The term ID.
     * @return marketType The proof market model category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ProofMarketType marketType,
            AttackType      attack,
            DefenseType     defense,
            uint256         timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.marketType, t.attack, t.defense, t.timestamp);
    }
}
