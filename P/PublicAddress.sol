// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PublicAddressRegistry
 * @notice Defines “Public Address” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PublicAddressRegistry {
    /// @notice Types of public addresses
    enum PublicAddressType {
        ExternallyOwnedAccount, // EOA controlled by a private key
        ContractAddress,        // smart contract address
        VanityAddress,          // customized address prefix
        StealthAddress,         // one-time use stealth address
        MultisigWallet          // address requiring multiple signatures
    }

    /// @notice Attack vectors targeting public addresses
    enum AttackType {
        KeyCompromise,    // theft of the private key
        Phishing,         // tricking user into revealing address controls
        Spoofing,         // presenting a fake address (e.g. QR code)
        ReplayAttack,     // reusing a signed transaction on a fork
        DustingAttack     // sending tiny amounts to deanonymize
    }

    /// @notice Defense mechanisms for securing public addresses
    enum DefenseType {
        HardwareWallet,       // store keys in a hardware device
        MultiSig,             // require multiple approvals for actions
        AddressChecksum,      // validate checksummed addresses
        ColdStorage,          // keep keys offline in cold wallets
        AddressWhitelist      // restrict outgoing transactions to known addresses
    }

    struct Term {
        PublicAddressType addrType;
        AttackType        attack;
        DefenseType       defense;
        uint256           timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed        id,
        PublicAddressType      addrType,
        AttackType             attack,
        DefenseType            defense,
        uint256                timestamp
    );

    /**
     * @notice Register a new Public Address term.
     * @param addrType The category of the public address.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PublicAddressType addrType,
        AttackType        attack,
        DefenseType       defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            addrType:  addrType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, addrType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Public Address term.
     * @param id The term ID.
     * @return addrType   The public address category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PublicAddressType addrType,
            AttackType        attack,
            DefenseType       defense,
            uint256           timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.addrType, t.attack, t.defense, t.timestamp);
    }
}
