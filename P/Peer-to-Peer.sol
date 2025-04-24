// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PeerToPeerRegistry
 * @notice Defines “Peer-to-Peer (P2P)” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PeerToPeerRegistry {
    /// @notice Types of peer-to-peer models
    enum P2PType {
        Payment,            // person-to-person payments
        Lending,            // lending/borrowing between peers
        Exchange,           // direct asset swaps
        Marketplace,        // P2P goods/services marketplace
        Communication       // direct messaging or data sharing
    }

    /// @notice Attack vectors targeting P2P systems
    enum AttackType {
        SybilAttack,        // fake identities to subvert consensus
        EclipseAttack,      // isolating a node from honest peers
        DoubleSpending,     // spending same asset twice
        Phishing,           // tricking users into sending to wrong party
        DOS                 // denial-of-service to disrupt service
    }

    /// @notice Defense mechanisms for P2P systems
    enum DefenseType {
        ReputationSystem,   // trust scores for participants
        MultiFactorAuth,    // require additional verification
        Encryption,         // secure messaging/data channels
        RateLimiting,       // throttle requests to prevent spam
        Escrow              // third-party hold of funds until conditions met
    }

    struct Term {
        P2PType     p2pType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        P2PType     p2pType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new P2P term.
     * @param p2pType  The peer-to-peer model category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        P2PType     p2pType,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            p2pType:    p2pType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, p2pType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered P2P term.
     * @param id The term ID.
     * @return p2pType  The peer-to-peer model category.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            P2PType     p2pType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.p2pType, t.attack, t.defense, t.timestamp);
    }
}
