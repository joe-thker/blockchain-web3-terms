// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OEVRegistry
 * @notice Defines Oracle Extractable Value (OEV) categories along with
 *         common attack vectors and defense mechanisms. Users can
 *         register and query these combinations on‑chain for analysis
 *         or governance.
 */
contract OEVRegistry {
    /// @notice Categories of OEV exploits
    enum OEVType {
        PriceTampering,         // manipulating price reports
        DataPoisoning,          // feeding corrupted data
        TimestampManipulation,  // abusing block timestamp in reports
        FlashLoanOrchestration, // using flash loans to skew oracle state
        FeeSniping              // bidding up gas to win oracle updates
    }

    /// @notice Attack vectors targeting oracle systems
    enum AttackType {
        FakeReport,    // submitting fabricated price/data
        Collusion,     // proposers & validators colluding
        HighFeeSpam,   // spamming high‑fee transactions
        Sandwich,      // front‑run/back‑run around updates
        Replay         // replaying old reports at advantageous times
    }

    /// @notice Defense mechanisms to mitigate OEV
    enum DefenseType {
        MultiOracle,     // aggregate multiple independent oracles
        TimelockVerify,  // delay settlement for off‑chain checks
        Slashing,        // penalize misbehaving reporters
        FeeCap,          // cap gas fees for oracle submissions
        WatchTower       // off‑chain watchers alert on anomalies
    }

    struct OEVTerm {
        OEVType     oev;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => OEVTerm) public terms;

    event OEVTermRegistered(
        uint256 indexed id,
        OEVType     oev,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new OEV term.
     * @param oev     The OEV category.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the registered term.
     */
    function registerTerm(
        OEVType     oev,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = OEVTerm({
            oev:       oev,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit OEVTermRegistered(id, oev, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return oev       The OEV category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OEVType     oev,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        OEVTerm storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.oev, t.attack, t.defense, t.timestamp);
    }
}
