// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProtocolRegistry
 * @notice Defines “Protocol” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ProtocolRegistry {
    /// @notice Types of protocols
    enum ProtocolType {
        Payment,            // on-chain value transfer protocols
        Messaging,          // inter-protocol communication
        Oracle,             // price/feed oracle protocols
        Governance,         // on-chain governance mechanisms
        Bridge,             // cross-chain bridge protocols
        DataAvailability    // data-availability and indexing
    }

    /// @notice Attack vectors targeting protocols
    enum AttackType {
        SybilAttack,        // forging multiple identities
        ManInTheMiddle,     // intercepting or altering messages
        ReplayAttack,       // reusing old valid transactions
        Censorship,         // blocking or delaying protocol messages
        UpgradeHijack       // malicious governance/upgrade proposals
    }

    /// @notice Defense mechanisms for protocols
    enum DefenseType {
        Authentication,     // verify actor identities
        Encryption,         // encrypt messages and payloads
        NonceUsage,         // include nonces to prevent replays
        Decentralization,   // distribute roles across many nodes
        GovernanceSafeguard // timelocks and multisig for upgrades
    }

    struct Term {
        ProtocolType protocol;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        ProtocolType       protocol,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Protocol term.
     * @param protocol The protocol category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        ProtocolType protocol,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            protocol:  protocol,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, protocol, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Protocol term.
     * @param id The term ID.
     * @return protocol  The protocol category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ProtocolType protocol,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.protocol, t.attack, t.defense, t.timestamp);
    }
}
