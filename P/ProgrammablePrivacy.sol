// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProgrammablePrivacyRegistry
 * @notice Defines “Programmable Privacy” categories along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ProgrammablePrivacyRegistry {
    /// @notice Types of programmable privacy approaches
    enum PrivacyType {
        ZeroKnowledge,            // zk-SNARKs/zk-STARKs integration
        ConfidentialTransactions, // encrypted transaction amounts/recipients
        MPCIntegration,           // multi-party computation for privacy
        HomomorphicEncryption,    // compute on encrypted data
        PrivateRollups            // rollups with embedded privacy layer
    }

    /// @notice Attack vectors targeting privacy systems
    enum AttackType {
        Deanonymization,     // linking on-chain IDs to real identities
        SideChannelLeak,     // leaking data via timing/usage patterns
        FaultInjection,      // inducing errors to extract secrets
        LinkabilityAttack,   // correlating multiple transactions
        DataPoisoning        // feeding malicious inputs to break proofs
    }

    /// @notice Defense mechanisms for programmable privacy
    enum DefenseType {
        zkProofs,            // enforce zero-knowledge proofs
        SecretSharing,       // split secrets via MPC/shamir’s scheme
        HEEncryption,        // homomorphic encryption safeguards
        DifferentialPrivacy, // add noise to data outputs
        MixNets              // route transactions through mixers
    }

    struct Term {
        PrivacyType privacy;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PrivacyType privacy,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Programmable Privacy term.
     * @param privacy The privacy approach type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PrivacyType privacy,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            privacy:   privacy,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, privacy, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered privacy term.
     * @param id The term ID.
     * @return privacy   The privacy approach type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PrivacyType privacy,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.privacy, t.attack, t.defense, t.timestamp);
    }
}
