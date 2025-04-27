// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PortfolioTrackingRegistry
 * @notice Defines “Portfolio Tracking” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PortfolioTrackingRegistry {
    /// @notice Types of portfolio tracking approaches
    enum TrackingType {
        Manual,             // user‐driven periodic checks
        RealTime,           // continuous live updates
        PeriodicRebalance,  // scheduled rebalancing snapshots
        AutomatedAlerts,    // threshold or anomaly alerts
        SocialCopying       // mirror another user’s portfolio
    }

    /// @notice Attack vectors targeting tracking systems
    enum AttackType {
        DataManipulation,    // tampering with price or position data
        UnauthorizedAccess,  // stealing credentials/API keys
        OracleManipulation,  // feeding wrong oracle prices
        DelayedUpdates,      // intentionally slowing data feeds
        DenialOfService      // overwhelming tracking endpoints
    }

    /// @notice Defense mechanisms for tracking systems
    enum DefenseType {
        Encryption,          // TLS/SSL and data‐at‐rest encryption
        AccessControl,       // role‐based or API key permissions
        OracleRedundancy,    // multiple independent price feeds
        DataRedundancy,      // replica databases/backups
        RateLimiting         // throttle requests to prevent DoS
    }

    struct Term {
        TrackingType tracking;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        TrackingType tracking,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Portfolio Tracking term.
     * @param tracking The portfolio tracking approach.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        TrackingType tracking,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            tracking:  tracking,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, tracking, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return tracking  The portfolio tracking approach.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            TrackingType tracking,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.tracking, t.attack, t.defense, t.timestamp);
    }
}
