// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QubitRegistry
 * @notice Defines “Quantum Bit (Qubit)” types along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract QubitRegistry {
    /// @notice Types of qubit implementations
    enum QubitType {
        Superconducting,   // qubits based on superconducting circuits
        IonTrap,          // qubits using trapped ions
        Topological,      // qubits using anyon braiding
        Photonic,         // qubits encoded in photon states
        SpinBased         // qubits using electron or nuclear spin
    }

    /// @notice Attack vectors targeting qubit systems
    enum AttackType {
        Decoherence,      // loss of quantum coherence over time
        Crosstalk,        // unwanted coupling between qubits
        MeasurementError, // errors in qubit readout
        ControlPulseError,// imprecise quantum gate pulses
        ThermalNoise      // noise from thermal fluctuations
    }

    /// @notice Defense mechanisms for qubit stability
    enum DefenseType {
        ErrorCorrection,  // quantum error correction codes
        QubitShielding,   // physical shielding from environment
        PulseCalibration, // fine-tune control pulses dynamically
        CryogenicCooling, // maintain ultra-low temperatures
        IsolationTechniques // decouple from unwanted interactions
    }

    struct Term {
        QubitType   qubitType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        QubitType   qubitType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Qubit term.
     * @param qubitType The qubit implementation type.
     * @param attack    The anticipated attack (error) vector.
     * @param defense   The chosen defense (mitigation) mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        QubitType   qubitType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            qubitType: qubitType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, qubitType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Qubit term.
     * @param id The term ID.
     * @return qubitType The qubit implementation type.
     * @return attack    The error/attack vector.
     * @return defense   The mitigation mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            QubitType   qubitType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.qubitType, t.attack, t.defense, t.timestamp);
    }
}
