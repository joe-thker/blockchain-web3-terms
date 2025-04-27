// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PrivateBlockchainRegistry
 * @notice Defines “Private Blockchain” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PrivateBlockchainRegistry {
    /// @notice Types of private blockchain deployments
    enum PrivateBlockchainType {
        SingleParty,       // operated by one organization
        Consortium,        // shared by a group of organizations
        Federated,         // multiple trusted entities with shared governance
        Hybrid,            // mix of public and private components
        Enterprise         // enterprise-specific, permissioned network
    }

    /// @notice Attack vectors targeting private blockchains
    enum AttackType {
        InsiderAttack,     // malicious actions by authorized insiders
        NodeCompromise,    // unauthorized takeover of a node
        ConsensusManipulation, // collusion to subvert consensus
        DataTampering,     // altering ledger data off-chain
        DenialOfService    // flooding nodes to disrupt service
    }

    /// @notice Defense mechanisms for private blockchains
    enum DefenseType {
        AccessControl,     // strict role-based permissions
        Encryption,        // data encryption in transit and at rest
        MultiSignature,    // multisig approvals for critical operations
        Auditing,          // on-chain/off-chain audit trails
        Redundancy         // geo-distributed nodes for high availability
    }

    struct Term {
        PrivateBlockchainType chainType;
        AttackType            attack;
        DefenseType           defense;
        uint256               timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed      id,
        PrivateBlockchainType chainType,
        AttackType            attack,
        DefenseType           defense,
        uint256               timestamp
    );

    /**
     * @notice Register a new Private Blockchain term.
     * @param chainType The deployment category of the private blockchain.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        PrivateBlockchainType chainType,
        AttackType            attack,
        DefenseType           defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            chainType: chainType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, chainType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Private Blockchain term.
     * @param id The term ID.
     * @return chainType The deployment category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PrivateBlockchainType chainType,
            AttackType            attack,
            DefenseType           defense,
            uint256               timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.chainType, t.attack, t.defense, t.timestamp);
    }
}
