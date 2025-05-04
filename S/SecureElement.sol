// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SecureElementRegistry
 * @notice Defines “Secure Element” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract SecureElementRegistry {
    /// @notice Types of secure elements
    enum ElementType {
        SmartCardSE,       // embedded in smart cards (ISO/IEC 7816)
        EmbeddedSE,        // integrated into device hardware
        SIMBasedSE,        // secure SIM/UICC modules
        TPM,               // Trusted Platform Module chip
        SEOnChip           // secure enclave within SoC
    }

    /// @notice Attack vectors targeting secure elements
    enum AttackType {
        PhysicalTampering, // decapping or fault injection
        SideChannel,       // power/timing electromagnetic analysis
        FaultInjection,    // glitch attacks to bypass checks
        OTPExtraction,     // extracting keys via EM or laser probing
        SupplyChainHijack  // embedding malicious microcode
    }

    /// @notice Defense mechanisms for securing elements
    enum DefenseType {
        ShieldEncapsulation, // hardened packaging against tamper
        ConstantPower,       // mask power consumption patterns
        RedundantChecks,     // internal consistency verifications
        SecureBootloader,    // verify firmware integrity on startup
        OnChipKeyDerivation  // derive keys internally without export
    }

    struct Term {
        ElementType element;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ElementType    element,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new Secure Element term.
     * @param element The secure element variant.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id     The ID of the newly registered term.
     */
    function registerTerm(
        ElementType element,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            element:   element,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, element, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Secure Element term.
     * @param id The term ID.
     * @return element   The secure element variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ElementType element,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.element, t.attack, t.defense, t.timestamp);
    }
}
