// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PermissionedLedgerRegistry
 * @notice Defines “Permissioned Ledger” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PermissionedLedgerRegistry {
    /// @notice Types of permissioned ledgers
    enum PermissionedLedgerType {
        Consortium,        // governed by a consortium of organizations
        Private,           // single-entity managed ledger
        Federated,         // multiple trusted entities with shared control
        Hybrid,            // mix of public and private permissions
        PublicWithAuth     // public ledger requiring authentication
    }

    /// @notice Attack vectors targeting permissioned ledgers
    enum AttackType {
        InsiderAttack,     // malicious action by an authorized insider
        Censorship,        // blocking or delaying transactions
        Sybil,             // creating fake identities to influence consensus
        Collusion,         // subset of nodes collude to subvert rules
        KeyCompromise      // private key theft of validator or node
    }

    /// @notice Defense mechanisms for permissioned ledgers
    enum DefenseType {
        Authentication,    // strong identity verification for participants
        AccessControl,     // role-based or attribute-based access policies
        Auditing,          // on-chain/off-chain audit trails and logs
        Encryption,        // data encryption at rest and in transit
        MultiSignature     // require multiple signatures for critical ops
    }

    struct Term {
        PermissionedLedgerType ledgerType;
        AttackType             attack;
        DefenseType            defense;
        uint256                timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PermissionedLedgerType ledgerType,
        AttackType             attack,
        DefenseType            defense,
        uint256                timestamp
    );

    /**
     * @notice Register a new Permissioned Ledger term.
     * @param ledgerType The permissioned ledger category.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        PermissionedLedgerType ledgerType,
        AttackType             attack,
        DefenseType            defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            ledgerType: ledgerType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, ledgerType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Permissioned Ledger term.
     * @param id The term ID.
     * @return ledgerType The permissioned ledger category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PermissionedLedgerType ledgerType,
            AttackType             attack,
            DefenseType            defense,
            uint256                timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.ledgerType, t.attack, t.defense, t.timestamp);
    }
}
