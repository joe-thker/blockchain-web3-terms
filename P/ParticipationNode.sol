// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ParticipationNodeRegistry
 * @notice Defines “Participation Node” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ParticipationNodeRegistry {
    /// @notice Types of participation nodes in a blockchain network
    enum NodeType {
        Validator,         // produces and finalizes blocks
        FullNode,          // stores full blockchain history
        LightClient,       // verifies headers only
        ArchiveNode,       // stores archive states and history
        EdgeNode           // connects end-users to the network
    }

    /// @notice Attack vectors targeting participation nodes
    enum AttackType {
        Sybil,             // multiple identities to influence consensus
        DDoS,              // denial-of-service to disrupt node availability
        Equivocation,      // sending conflicting messages/blocks
        Eclipse,           // isolating node from honest peers
        SlashingAttack     // tricking into double-signing to slash stake
    }

    /// @notice Defense mechanisms for participation nodes
    enum DefenseType {
        StakingRequirements, // minimum stake to become/keep node status
        DDoSProtection,      // services or protocols to mitigate DDoS
        Monitoring,          // on-chain/off-chain health checks & alerts
        FinalityGadget,      // overlay protocols to finalize state
        ReputationSystem     // track node behavior and penalize misbehavior
    }

    struct Term {
        NodeType    nodeType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        NodeType    nodeType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Participation Node term.
     * @param nodeType The category of the participation node.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        NodeType    nodeType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            nodeType:  nodeType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, nodeType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Participation Node term.
     * @param id The term ID.
     * @return nodeType The node category.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            NodeType    nodeType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.nodeType, t.attack, t.defense, t.timestamp);
    }
}
