// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuasarSmartContractRegistry
 * @notice Defines “Quasar Smart Contract (OMG Foundation)” variants along with common
 *         attack vectors and defense mechanisms. Users can register and query
 *         these combinations on-chain for analysis or governance.
 */
contract QuasarSmartContractRegistry {
    /// @notice Types of Quasar deployments/features
    enum QuasarType {
        PlasmaClassic,      // original Plasma child chain
        CommitChain,        // state‐commitment chains
        RollupIntegration,  // optimistic or zk‐rollup bridges
        FraudProofModule,   // on‐chain fraud proof verification
        ExitMechanism       // exit channels/queue implementations
    }

    /// @notice Attack vectors targeting Quasar components
    enum AttackType {
        MassExit,           // rush exits to drain funds
        ProofWithholding,   // suppressing fraud proofs
        DataAvailability,   // withholding state data
        SmartContractBug,   // vulnerability in bridge or module
        SybilSpamming       // spamming exit requests to congest
    }

    /// @notice Defense mechanisms for Quasar security
    enum DefenseType {
        ChallengePeriod,    // allow time for fraud challenges
        BondedOperators,    // economic bonding for chain operators
        DataAvailabilityLayer, // use external DA networks
        FormalVerification, // verify critical modules off‐chain/on‐chain
        RateLimiting        // throttle exits and state submissions
    }

    struct Term {
        QuasarType  quasarType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        QuasarType  quasarType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Quasar Smart Contract term.
     * @param quasarType The Quasar feature or module type.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        QuasarType  quasarType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            quasarType: quasarType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, quasarType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Quasar term.
     * @param id The term ID.
     * @return quasarType The Quasar feature or module type.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            QuasarType  quasarType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.quasarType, t.attack, t.defense, t.timestamp);
    }
}
