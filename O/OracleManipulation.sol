// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OracleManipulationRegistry
 * @notice Defines subtypes of Oracle Manipulation along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on‑chain for analysis or governance.
 */
contract OracleManipulationRegistry {
    /// @notice Categories of Oracle Manipulation
    enum OracleManipulationType {
        PriceSpoofing,       // feeding incorrect price data
        TimestampSpoofing,   // abusing timestamps in oracle reports
        DataPoisoning,       // injecting corrupted data
        Collusion,           // proposers and validators collude
        FlashLoanAttack      // using flash loans to skew oracle results
    }

    /// @notice Specific attack vectors against oracle systems
    enum AttackType {
        FakeReport,          // submitting fabricated reports
        FrontRunning,        // ordering exploits around updates
        SybilAttack,         // multiple identities to influence consensus
        Replay,              // replaying old valid reports
        Censorship           // blocking genuine updates
    }

    /// @notice Defense mechanisms to mitigate oracle manipulation
    enum DefenseType {
        MultiOracle,         // aggregate multiple independent oracles
        Slashing,            // penalize misbehavior with stake slashing
        WatchTower,          // off‑chain watchers alert on anomalies
        TimelockVerify,      // delay settlement for manual verification
        Redundancy           // redundant reporting to ensure availability
    }

    struct Term {
        OracleManipulationType manipulation;
        AttackType             attack;
        DefenseType            defense;
        uint256                timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        OracleManipulationType manipulation,
        AttackType             attack,
        DefenseType            defense,
        uint256                timestamp
    );

    /**
     * @notice Register a new Oracle Manipulation term.
     * @param manipulation The category of oracle manipulation.
     * @param attack       The anticipated attack vector.
     * @param defense      The chosen defense mechanism.
     * @return id          The ID of the registered term.
     */
    function registerTerm(
        OracleManipulationType manipulation,
        AttackType             attack,
        DefenseType            defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            manipulation: manipulation,
            attack:       attack,
            defense:      defense,
            timestamp:    block.timestamp
        });
        emit TermRegistered(id, manipulation, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return manipulation The oracle manipulation category.
     * @return attack       The attack vector.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OracleManipulationType manipulation,
            AttackType             attack,
            DefenseType            defense,
            uint256                timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.manipulation, t.attack, t.defense, t.timestamp);
    }
}
