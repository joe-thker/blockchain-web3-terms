// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PhysicalBitcoinRegistry
 * @notice Defines “Physical Bitcoins” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PhysicalBitcoinRegistry {
    /// @notice Types of physical Bitcoin embodiments
    enum PhysicalBitcoinType {
        CasasciusCoin,        // metal coin with embedded private key seal
        OpenDimeUSB,         // USB stick cold wallet
        CoinShieldCard,      // tamper‐evident card
        CasasciusReplica,    // uncertified replicas
        Custom               // any other physical form
    }

    /// @notice Attack vectors against physical Bitcoins
    enum AttackType {
        Theft,               // outright stealing of coin/device
        Counterfeit,         // creating fake versions
        Tampering,           // breaking seal to extract key
        PrivateKeyExtraction,// physically extracting the key material
        PhysicalDamage       // destroying the device/coin
    }

    /// @notice Defense mechanisms for physical Bitcoins
    enum DefenseType {
        TamperProofSeal,         // seals that visibly break
        TrustedIssuerCertification, // issuer guarantees authenticity
        ColdStorageVault,        // secure physical vault storage
        MultiSigKeySplit,        // split key across multiple shares
        InsuranceCoverage        // insure against theft or loss
    }

    struct Term {
        PhysicalBitcoinType pbType;
        AttackType          attack;
        DefenseType         defense;
        uint256             timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PhysicalBitcoinType pbType,
        AttackType          attack,
        DefenseType         defense,
        uint256             timestamp
    );

    /**
     * @notice Register a new Physical Bitcoin term.
     * @param pbType   The physical Bitcoin form.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PhysicalBitcoinType pbType,
        AttackType          attack,
        DefenseType         defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            pbType:    pbType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, pbType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return pbType    The physical Bitcoin form.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PhysicalBitcoinType pbType,
            AttackType          attack,
            DefenseType         defense,
            uint256             timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.pbType, t.attack, t.defense, t.timestamp);
    }
}
