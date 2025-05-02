// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RelayChainRegistry
 * @notice Defines “Relay Chain” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RelayChainRegistry {
    /// @notice Types of relay chains
    enum RelayChainType {
        Polkadot,           // Polkadot relay chain for parachains
        Kusama,             // Kusama relay chain for canary networks
        CosmosHub,          // Cosmos hub for IBC-connected zones
        LayerZero,          // LayerZero’s generic messaging layer
        Axelar              // Axelar’s cross-chain communication network
    }

    /// @notice Attack vectors targeting relay chains
    enum AttackType {
        CollatorCensorship, // collator nodes censor cross-chain messages
        ValidatorBribe,     // bribing validators to accept invalid messages
        OracleManipulation, // corrupting cross-chain price oracles
        MessageReplay,      // replaying old cross-chain messages
        SybilAttack         // spinning up nodes to influence consensus
    }

    /// @notice Defense mechanisms for securing relay chains
    enum DefenseType {
        DecentralizedCollation, // large, diverse set of collators
        MultiSignatureFinality, // require multi-signature for finality proofs
        MultiOracleFeeds,       // aggregate multiple oracle inputs
        ReplayProtection,       // nonces and timeouts on messages
        GovernanceTimelock      // timelocked governance for protocol changes
    }

    struct Term {
        RelayChainType relayType;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        RelayChainType     relayType,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Relay Chain term.
     * @param relayType The relay chain variant.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        RelayChainType relayType,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            relayType: relayType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, relayType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Relay Chain term.
     * @param id The term ID.
     * @return relayType The relay chain variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RelayChainType relayType,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.relayType, t.attack, t.defense, t.timestamp);
    }
}
