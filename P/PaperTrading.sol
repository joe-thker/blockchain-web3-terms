// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PaperTradingRegistry
 * @notice Defines “Paper Trading” modes along with common
 *         attack vectors and defense mechanisms. Users can
 *         register and query these combinations on-chain for
 *         analysis or governance.
 */
contract PaperTradingRegistry {
    /// @notice Types of paper trading environments
    enum PaperTradingType {
        Simulated,       // fully simulated order execution
        Replay,          // replay historic market data
        AlgorithmTest,   // algorithm backtesting mode
        ManualDemo,      // manual UI-driven demo
        MixedReality     // live data with simulated execution
    }

    /// @notice Attack vectors targeting paper trading setups
    enum AttackType {
        DataSpoofing,    // feeding incorrect market data
        ReplayManipulation, // altering replayed history
        LatencyInjection,  // delaying data feeds artificially
        FrontRunningSim,   // simulated MEV to mislead users
        CredentialLeak     // unauthorized access to demo accounts
    }

    /// @notice Defense mechanisms for paper trading
    enum DefenseType {
        DataValidation,  // verify data against multiple sources
        ImmutableLogs,   // tamper-evident replay logs
        TimeSyncChecks,  // ensure consistent timestamps
        SandboxIsolation,// isolate demo environment from prod
        AccessControls   // restrict demo credentials usage
    }

    struct Term {
        PaperTradingType paperMode;
        AttackType       attack;
        DefenseType      defense;
        uint256          timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PaperTradingType paperMode,
        AttackType       attack,
        DefenseType      defense,
        uint256          timestamp
    );

    /**
     * @notice Register a new Paper Trading term.
     * @param paperMode The paper trading environment type.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        PaperTradingType paperMode,
        AttackType       attack,
        DefenseType      defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            paperMode: paperMode,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, paperMode, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return paperMode The paper trading environment type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PaperTradingType paperMode,
            AttackType       attack,
            DefenseType      defense,
            uint256          timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.paperMode, t.attack, t.defense, t.timestamp);
    }
}
