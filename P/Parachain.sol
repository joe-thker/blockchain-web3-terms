// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ParachainRegistry
 * @notice Defines “Parachain” categories along with common attack vectors
 *         and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract ParachainRegistry {
    /// @notice Types of Polkadot/Substrate parachains
    enum ParachainType {
        RelayChain,              // the central security-providing chain
        Utility,                 // for specialized services (e.g. oracles)
        SmartContractPlatform,   // full EVM or WASM smart contracts
        Identity,                // identity or registry chains
        DataAvailability         // chains dedicated to DA services
    }

    /// @notice Attack vectors targeting parachains
    enum AttackType {
        CollusionAmongValidators, // validators collude to finalize bad blocks
        InvalidStateTransition,   // proposing a block with bad state roots
        Downtime,                 // prolonged unavailability of collators
        SlashingAttack,           // triggering incorrect slashing of honest nodes
        ExitScam                  // collators abscond with user funds
    }

    /// @notice Defense mechanisms for parachains
    enum DefenseType {
        SharedSecurity,           // securing with relay-chain validator set
        ValidatorBonding,         // requiring substantial stake from collators
        CrossChainVerification,   // proof checks on relay-chain for state roots
        OnChainMonitoring,        // real-time monitoring and alerting
        GovernanceFallback        // council-driven emergency intervention
    }

    struct Term {
        ParachainType parachain;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ParachainType parachain,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Parachain term.
     * @param parachain The parachain category.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        ParachainType parachain,
        AttackType    attack,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            parachain: parachain,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, parachain, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Parachain term.
     * @param id The term ID.
     * @return parachain The parachain category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ParachainType parachain,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.parachain, t.attack, t.defense, t.timestamp);
    }
}
