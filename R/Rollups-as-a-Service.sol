// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RollupsAsAServiceRegistry
 * @notice Defines “Rollups-as-a-Service” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RollupsAsAServiceRegistry {
    /// @notice Types of Rollups-as-a-Service offerings
    enum RaaSType {
        ZKRollup,             // zk-SNARK/zk-STARK based rollup
        OptimisticRollup,     // fraud-proof based rollup
        Validium,             // off-chain data availability rollup
        Plasma,               // UTXO-style sidechain rollup
        Sidechain             // sovereign sidechain with rollup interface
    }

    /// @notice Attack vectors targeting rollup services
    enum AttackType {
        DataAvailabilityAttack, // withholding or corrupting DA
        FraudProofDelay,        // delaying submission of fraud proofs
        ValidatorCollusion,     // colluding to produce invalid state
        SequencerCensorship,    // censoring transactions at sequencer
        MEVExtraction           // capturing MEV at rollup layer
    }

    /// @notice Defense mechanisms for rollup security
    enum DefenseType {
        DACommittee,        // decentralized data availability committee
        FastFraudProofs,    // rapid on-chain fraud proof resolution
        MultiSequencer,     // competing sequencers to prevent censorship
        WatchtowerServices, // off-chain watchers monitoring misbehavior
        OnchainFallback     // fallback to L1 for data and dispute
    }

    struct Term {
        RaaSType    serviceType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RaaSType    serviceType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Rollups-as-a-Service term.
     * @param serviceType The RaaS variant.
     * @param attack      The anticipated attack vector.
     * @param defense     The chosen defense mechanism.
     * @return id         The ID of the newly registered term.
     */
    function registerTerm(
        RaaSType    serviceType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            serviceType: serviceType,
            attack:      attack,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit TermRegistered(id, serviceType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return serviceType The RaaS variant.
     * @return attack      The attack vector.
     * @return defense     The defense mechanism.
     * @return timestamp   When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RaaSType    serviceType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.serviceType, t.attack, t.defense, t.timestamp);
    }
}
