// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfAuthorityRegistry
 * @notice Defines “Proof-of-Authority” consensus models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ProofOfAuthorityRegistry {
    /// @notice Types of Proof-of-Authority consensus setups
    enum AuthorityModel {
        SingleAuthority,      // one entity signs all blocks
        ConsortiumAuthority,  // group of pre-approved validators
        RotatingAuthority,    // authority rotates among a set
        MultiSigAuthority,    // multi-signature block approval
        PermissionedAuthority // permissioned nodes with ACLs
    }

    /// @notice Attack vectors targeting PoA networks
    enum AttackType {
        KeyCompromise,        // stealing a validator’s private key
        Collusion,            // validators collude to censor or fork
        DDoS,                 // denial-of-service against authority nodes
        InsiderAttack,        // malicious action by an authorized insider
        PermissionEscalation  // unauthorized node granted authority
    }

    /// @notice Defense mechanisms for PoA security
    enum DefenseType {
        HSMIsolation,         // keys stored in hardware security modules
        MultiSigApproval,     // require multiple signatures per block
        ValidatorRotation,    // rotate authority periodically
        AccessControlList,    // strict on-chain ACL for validator set
        MonitoringAndAlerts   // real-time monitoring with alerts
    }

    struct Term {
        AuthorityModel model;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        AuthorityModel     model,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Proof-of-Authority term.
     * @param model   The PoA model type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        AuthorityModel model,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            model:     model,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, model, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered PoA term.
     * @param id The term ID.
     * @return model     The PoA model type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            AuthorityModel model,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.model, t.attack, t.defense, t.timestamp);
    }
}
