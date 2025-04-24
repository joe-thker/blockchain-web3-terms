// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PegRegistry
 * @notice Defines “Peg” categories along with common attack vectors
 *         and defense mechanisms. Users can register and query
 *         these combinations on-chain for analysis or governance.
 */
contract PegRegistry {
    /// @notice Types of pegs for assets or currencies
    enum PegType {
        HardPeg,          // fixed 1:1 peg
        SoftPeg,          // peg maintained within a band
        DynamicPeg,       // peg adjusted algorithmically
        AlgorithmicPeg,   // no collateral, relies on supply mechanics
        DualPeg           // peg to two reference assets
    }

    /// @notice Attack vectors targeting pegs
    enum AttackType {
        OracleManipulation,   // feeding wrong price data to depeg
        CollateralShock,      // sudden drop in collateral value
        MarketFlooding,       // overwhelming liquidity pools
        GovernanceAttack,     // hijacking upgrade/governance process
        ArbitrageAttack       // persistent arbitrage draining reserves
    }

    /// @notice Defense mechanisms to protect pegs
    enum DefenseType {
        OverCollateralization,  // hold excess collateral buffer
        RebalancingMechanism,    // auto-rebalance reserves
        CircuitBreaker,         // pause operations on stress
        OracleRedundancy,       // multiple independent price sources
        GovernanceSafeguard     // multisig or timelock for changes
    }

    struct Term {
        PegType     pegType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event PegTermRegistered(
        uint256 indexed id,
        PegType     pegType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Peg term.
     * @param pegType  The peg category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PegType     pegType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            pegType:   pegType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit PegTermRegistered(id, pegType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Peg term.
     * @param id The term ID.
     * @return pegType   The peg category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PegType     pegType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.pegType, t.attack, t.defense, t.timestamp);
    }
}
