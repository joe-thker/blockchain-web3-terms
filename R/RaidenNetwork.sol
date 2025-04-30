// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RaidenNetworkRegistry
 * @notice Defines “Raiden Network” channel types along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RaidenNetworkRegistry {
    /// @notice Types of Raiden channel modes
    enum ChannelMode {
        Direct,           // direct payment channel between two participants
        Mediated,         // routed via multiple channels (via mediator)
        HubAndSpoke,      // star topology through a central hub
        MicroTransfer,    // frequent micro-payments optimized channel
        TokenSwap         // cross-token swap channel
    }

    /// @notice Attack vectors targeting Raiden channels
    enum AttackType {
        Griefing,         // locking funds in unsettled channels
        Flooding,         // sending excessive mediated transfers
        FeeManipulation,  // exploit fee setting in routing
        BalanceProofSeal, // withholding balance proof to lock funds
        CollusiveMediator // mediator and receiver collude to cheat
    }

    /// @notice Defense mechanisms for Raiden security
    enum DefenseType {
        MonitoringService,   // off-chain watchers to detect misbehavior
        OnChainSettlement,   // settle disputes on-chain promptly
        FeeCap,              // enforce maximum routing fees
        TimeLocks,           // use HTLC timeouts to secure transfers
        StrictChannelClose   // require proof on channel close
    }

    struct Term {
        ChannelMode mode;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ChannelMode   mode,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Raiden Network term.
     * @param mode    The payment channel mode.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id     The ID of the newly registered term.
     */
    function registerTerm(
        ChannelMode mode,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            mode:      mode,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, mode, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Raiden Network term.
     * @param id The term ID.
     * @return mode      The payment channel mode.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ChannelMode mode,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.mode, t.attack, t.defense, t.timestamp);
    }
}
