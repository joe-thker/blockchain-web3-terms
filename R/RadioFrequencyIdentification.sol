// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RFIDRegistry
 * @notice Defines “Radio Frequency Identification (RFID)” categories along with common
 *         attack vectors and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract RFIDRegistry {
    /// @notice Types of RFID tags/readers
    enum RFIDType {
        PassiveTag,       // no internal power, powered by reader field
        ActiveTag,        // battery-powered tag with longer range
        SemiPassiveTag,   // battery-assisted response but passive communication
        NFC,              // near-field communication variant (~13.56 MHz)
        UHF               // ultra-high frequency (~860–960 MHz) for long range
    }

    /// @notice Attack vectors targeting RFID systems
    enum AttackType {
        Eavesdropping,    // intercepting tag–reader communications
        Cloning,          // duplicating tag data to a fake tag
        RelayAttack,      // forwarding communications to spoof distance
        Jamming,          // disrupting the RF field to block reads
        Spoofing          // acting as a rogue reader to extract data
    }

    /// @notice Defense mechanisms for securing RFID
    enum DefenseType {
        Encryption,       // encrypt tag–reader communication
        MutualAuth,       // require tag and reader authentication
        FrequencyHopping, // switch frequencies to avoid jamming
        SignalStrength,   // use RSSI to detect relay or abnormal reads
        TagKilling        // disable tags permanently after use
    }

    struct Term {
        RFIDType   rfidType;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RFIDType   rfidType,
        AttackType attack,
        DefenseType defense,
        uint256    timestamp
    );

    /**
     * @notice Register a new RFID term.
     * @param rfidType The RFID tag/reader category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        RFIDType   rfidType,
        AttackType attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            rfidType:   rfidType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, rfidType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered RFID term.
     * @param id The term ID.
     * @return rfidType The RFID tag/reader category.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RFIDType   rfidType,
            AttackType attack,
            DefenseType defense,
            uint256    timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.rfidType, t.attack, t.defense, t.timestamp);
    }
}
