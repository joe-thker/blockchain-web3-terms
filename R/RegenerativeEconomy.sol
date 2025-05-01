// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RegenerativeEconomyRegistry
 * @notice Defines “Regenerative Economy” models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RegenerativeEconomyRegistry {
    /// @notice Types of regenerative economy models
    enum EconomyType {
        CircularSupply,       // closed‐loop material and resource flows
        TokenIncentives,      // token rewards for sustainable actions
        ImpactBond,           // pay‐for‐success social impact bonds
        ResourcePooling,      // shared resource management (e.g., tools)
        DAOStewardship        // decentralized governance of commons
    }

    /// @notice Attack vectors targeting regenerative economy systems
    enum AttackType {
        Greenwashing,         // false claims of sustainability
        SybilManipulation,    // fake identities to claim incentives
        OracleCorruption,     // feeding incorrect impact data
        FrontRunning,         // MEV bots capturing token rewards
        ExitScam              // sudden withdrawal of project funds
    }

    /// @notice Defense mechanisms for securing regenerative economy
    enum DefenseType {
        VerifiableMetrics,    // on‐chain proofs of sustainable actions
        MultiOracleFeeds,     // aggregate multiple impact oracles
        SybilResistance,      // identity checks / reputation systems
        TimelockedRewards,    // vesting/incentive delays to deter abuse
        DAOTransparency       // public proposal/audit processes
    }

    struct Term {
        EconomyType economyType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        EconomyType   economyType,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Regenerative Economy term.
     * @param economyType The regenerative economy model.
     * @param attack      The anticipated attack vector.
     * @param defense     The chosen defense mechanism.
     * @return id         The ID of the newly registered term.
     */
    function registerTerm(
        EconomyType economyType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            economyType: economyType,
            attack:      attack,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit TermRegistered(id, economyType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Regenerative Economy term.
     * @param id The term ID.
     * @return economyType The regenerative economy model.
     * @return attack      The attack vector.
     * @return defense     The defense mechanism.
     * @return timestamp   When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            EconomyType economyType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.economyType, t.attack, t.defense, t.timestamp);
    }
}
