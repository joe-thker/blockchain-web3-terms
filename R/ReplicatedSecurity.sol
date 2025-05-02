// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReplicatedSecurityRegistry
 * @notice Defines “Replicated Security” models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ReplicatedSecurityRegistry {
    /// @notice Types of replicated security approaches
    enum SecurityType {
        MultiSig,            // multiple signatures required for critical ops
        ThresholdCrypto,     // M-of-N threshold key sharing
        ShardingSecurity,    // security via sharded key pieces
        WatchtowerAudits,    // external watchers monitoring state
        DecentralizedID      // users control identity attestation
    }

    /// @notice Attack vectors targeting replicated security
    enum AttackType {
        KeyCompromise,       // compromise of enough keys to break threshold
        InsiderCollusion,    // collusion among key holders or signers
        ShardReconstruction, // reconstructing secret from shards
        DenialOfService,     // preventing key holders from participating
        ReplayAttack         // reusing old signatures or authorizations
    }

    /// @notice Defense mechanisms for replicated security
    enum DefenseType {
        PeriodicKeyRotation, // regularly rotate keys or shards
        DistributedTrust,    // spread keys across independent parties
        SecureEnclave,       // use hardware enclaves for key storage
        TimeoutFallback,     // fallback procedures on unresponsive parties
        MultiFactorAuth      // require extra authentication factors
    }

    struct Term {
        SecurityType securityModel;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed  id,
        SecurityType     securityModel,
        AttackType       attack,
        DefenseType      defense,
        uint256          timestamp
    );

    /**
     * @notice Register a new Replicated Security term.
     * @param securityModel The replicated security approach.
     * @param attack        The anticipated attack vector.
     * @param defense       The chosen defense mechanism.
     * @return id           The ID of the newly registered term.
     */
    function registerTerm(
        SecurityType securityModel,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            securityModel: securityModel,
            attack:        attack,
            defense:       defense,
            timestamp:     block.timestamp
        });
        emit TermRegistered(id, securityModel, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Replicated Security term.
     * @param id The term ID.
     * @return securityModel The replicated security approach.
     * @return attack        The attack vector.
     * @return defense       The defense mechanism.
     * @return timestamp     When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            SecurityType securityModel,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.securityModel, t.attack, t.defense, t.timestamp);
    }
}
