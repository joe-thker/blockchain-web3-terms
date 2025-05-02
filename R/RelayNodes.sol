// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RelayNodesRegistry
 * @notice Defines “Relay Nodes” categories along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RelayNodesRegistry {
    /// @notice Types of relay nodes
    enum RelayNodeType {
        FullNode,           // fully validates and relays all messages
        LightNode,          // validates headers and relays proofs
        ArchiveNode,        // stores full historical state and data
        ValidatorNode,      // participates in consensus and block production
        WatchtowerNode      // monitors and enforces channel or message safety
    }

    /// @notice Attack vectors targeting relay nodes
    enum AttackType {
        Censorship,         // blocking or delaying message relay
        EclipseAttack,      // isolating node from honest peers
        ResourceExhaustion, // flooding node with bogus traffic
        DataPoisoning,      // feeding invalid or malicious state data
        SybilAttack         // fake peers to influence relay decisions
    }

    /// @notice Defense mechanisms for securing relay nodes
    enum DefenseType {
        RedundantConnectivity, // multiple independent peer connections
        MessageSigning,        // cryptographic signing of relay messages
        RateLimiting,          // throttle incoming request rates
        PeerReputation,        // only relay via trusted peer lists
        MonitoringAlerts       // real-time alerts on abnormal behavior
    }

    struct Term {
        RelayNodeType nodeType;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed   id,
        RelayNodeType     nodeType,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new Relay Nodes term.
     * @param nodeType The relay node category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        RelayNodeType nodeType,
        AttackType    attack,
        DefenseType   defense
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
     * @notice Retrieve details of a registered Relay Nodes term.
     * @param id The term ID.
     * @return nodeType  The relay node category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RelayNodeType nodeType,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.nodeType, t.attack, t.defense, t.timestamp);
    }
}
