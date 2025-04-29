// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PumpAndDumpRegistry
 * @notice Defines “Pump & Dump (P&D) Scheme” categories along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract PumpAndDumpRegistry {
    /// @notice Variants of pump & dump schemes
    enum PnDType {
        SmallCapToken,       // low-liquidity tokens targeted by whispers
        SocialMedia,         // coordinated hype via social platforms
        WashTrading,         // self-trading to inflate volume
        FlashLoanPump,       // use flash loans to drive false price spikes
        RugPullPump         // pump preceding rug pull exit
    }

    /// @notice Attack vectors in pump & dump operations
    enum AttackType {
        MarketManipulation,  // false orders to move price
        CoordinatedHype,     // collusion to generate artificial demand
        InsiderLeak,         // privileged info used to time the dump
        BotFarming,          // automated bots to amplify pump
        ExitScam             // abrupt sell-off dumping all inventory
    }

    /// @notice Defense mechanisms against pump & dump
    enum DefenseType {
        CircuitBreaker,      // pause trading on rapid price swings
        VolumeMonitoring,    // on-chain alerts for abnormal volume
        WhitelistTrading,    // restrict large buys to vetted participants
        TimeLockOrders,      // delay order execution to prevent spikes
        AntiBotFilters       // block known trading bot patterns
    }

    struct Term {
        PnDType     schemeType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PnDType     schemeType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Pump & Dump term.
     * @param schemeType The pump & dump variant.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        PnDType     schemeType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            schemeType: schemeType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, schemeType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered P&D term.
     * @param id The term ID.
     * @return schemeType The pump & dump variant.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PnDType     schemeType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.schemeType, t.attack, t.defense, t.timestamp);
    }
}
