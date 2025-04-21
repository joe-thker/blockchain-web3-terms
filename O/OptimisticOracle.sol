// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OptimisticOracleRegistry
 * @notice Defines Oracle types for an Optimistic Oracle, along with
 *         potential attack vectors and defense mechanisms. Users can
 *         register combinations of these types on‑chain for tracking
 *         or governance purposes.
 */
contract OptimisticOracleRegistry {
    /// @notice Types of requests supported by the Optimistic Oracle
    enum OracleType {
        PriceRequest,    // e.g. asset price query
        EventRequest,    // e.g. outcome of a real‑world event
        CustomRequest    // any other data query
    }

    /// @notice Attack vectors an Optimistic Oracle may face
    enum AttackType {
        DataManipulation,   // feeding incorrect data
        Collusion,          // proposer and validator collude
        Downtime,           // oracle unavailable / censored
        FrontRunning        // ordering exploits
    }

    /// @notice Defense mechanisms against oracle attacks
    enum DefenseType {
        DisputeResolution,  // challenge and dispute process
        FallbackOracle,     // use secondary oracle if primary fails
        Redundancy,         // multiple independent proposers
        TimeDelayVerify     // delayed settlement for replay
    }

    struct OracleTerm {
        OracleType  oracleType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => OracleTerm) public terms;

    event OracleTermRegistered(
        uint256 indexed id,
        OracleType  oracleType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Optimistic Oracle term.
     * @param oracleType The category of the oracle request.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the registered term.
     */
    function registerTerm(
        OracleType  oracleType,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = OracleTerm({
            oracleType:  oracleType,
            attack:      attack,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit OracleTermRegistered(id, oracleType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return oracleType The category of the oracle request.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OracleType  oracleType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        OracleTerm storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.oracleType, t.attack, t.defense, t.timestamp);
    }
}
