// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OraclesRegistry
 * @notice Defines general Oracle categories along with common
 *         attack vectors and defense mechanisms. Users can
 *         register and query these combinations on‑chain.
 */
contract OraclesRegistry {
    /// @notice Categories of oracles
    enum OracleType {
        PriceOracle,        // asset price feeds
        RandomnessOracle,   // verifiable randomness
        DataOracle,         // arbitrary off‑chain data
        EventOracle,        // real‑world event outcomes
        VerifiableOracle,   // proof‑based oracle (e.g., VRF)
        Custom              // any other oracle type
    }

    /// @notice Attack vectors targeting oracles
    enum AttackType {
        FakeData,           // submitting fabricated data
        Censorship,         // withholding or delaying updates
        Collusion,          // oracle operator collusion
        SybilAttack,        // using many identities to skew consensus
        FrontRunning        // MEV around oracle updates
    }

    /// @notice Defense mechanisms to protect oracles
    enum DefenseType {
        MultiOracle,        // aggregate multiple independent oracles
        FallbackOracle,     // use a secondary oracle on failure
        Redundancy,         // replicate data sources
        TimelockVerify,     // delay finalization for off‑chain checks
        Watchtower          // off‑chain monitoring and alerts
    }

    struct OracleTerm {
        OracleType  oracle;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => OracleTerm) public terms;

    event OracleTermRegistered(
        uint256 indexed id,
        OracleType  oracle,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Oracle term.
     * @param oracle   The category of the oracle.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id       The ID of the registered term.
     */
    function registerTerm(
        OracleType  oracle,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = OracleTerm({
            oracle:    oracle,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit OracleTermRegistered(id, oracle, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Oracle term.
     * @param id The term ID.
     * @return oracle   The oracle category.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OracleType  oracle,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        OracleTerm storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.oracle, t.attack, t.defense, t.timestamp);
    }
}
