// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumComputingRegistry
 * @notice Defines “Quantum Computing” categories along with common
 *         attack (error) vectors and defense (mitigation) mechanisms.
 *         Users can register and query these combinations on-chain for
 *         analysis or governance.
 */
contract QuantumComputingRegistry {
    /// @notice Types of quantum computing platforms
    enum PlatformType {
        Superconducting,   // IBM, Google style circuits
        IonTrap,          // trapped ion qubits
        Photonic,         // light-based quantum processors
        Topological,      // topological qubit approaches
        SpinQubit          // spin-based qubits (electron/nuclear)
    }

    /// @notice Error/attack vectors in quantum systems
    enum AttackType {
        Decoherence,      // loss of quantum coherence over time
        Crosstalk,        // unwanted qubit–qubit coupling
        GateFidelityLoss, // imperfect quantum gate operations
        Leakage,          // qubit state leaking outside computational subspace
        MeasurementError  // inaccuracies reading qubit state
    }

    /// @notice Defense/mitigation mechanisms for quantum errors
    enum DefenseType {
        QEC,              // quantum error correction codes
        DynamicalDecoupling, // pulse sequences to cancel noise
        CryogenicShield,  // ultra-low temperature shielding
        PulseCalibration, // real-time gate pulse tuning
        Isolation         // physical separation of qubits
    }

    struct Term {
        PlatformType platform;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PlatformType platform,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Quantum Computing term.
     * @param platform The quantum computing platform type.
     * @param attack   The anticipated error/attack vector.
     * @param defense  The chosen defense/mitigation mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PlatformType platform,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            platform:  platform,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, platform, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Quantum Computing term.
     * @param id The term ID.
     * @return platform  The quantum computing platform type.
     * @return attack    The error/attack vector.
     * @return defense   The defense/mitigation mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PlatformType platform,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.platform, t.attack, t.defense, t.timestamp);
    }
}
