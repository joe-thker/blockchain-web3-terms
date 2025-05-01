// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReFiRegistry
 * @notice Defines “Regenerative Finance (ReFi)” models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ReFiRegistry {
    /// @notice Types of ReFi models
    enum ReFiType {
        CarbonCredits,        // tokenized carbon offset credits
        ImpactTokens,         // tokens representing social/environmental impact
        CircularTreasury,     // treasury that funds regeneration projects
        RegenerativeDAO,      // DAO governed regeneration initiatives
        GreenBond             // blockchain-based sustainability bonds
    }

    /// @notice Attack vectors targeting ReFi systems
    enum AttackType {
        Greenwashing,         // false claims of environmental benefit
        OracleManipulation,   // feeding incorrect impact or price data
        SybilFarming,         // fake accounts claiming incentives
        FlashLoanExploit,     // using flash loans to abuse tokenomics
        ExitScam              // project team withdrawing all funds unexpectedly
    }

    /// @notice Defense mechanisms for securing ReFi models
    enum DefenseType {
        VerifiableOracles,    // multi-source on-chain oracle verification
        AuditedImpact,        // third-party audits of environmental claims
        StakingLocks,         // lock-up periods for ReFi tokens to align incentives
        DAOOversight,         // community governance and transparent proposals
        EmergencyCircuitBreak // pause or freeze in case of detected anomalies
    }

    struct Term {
        ReFiType   model;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ReFiType    model,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new ReFi term.
     * @param model    The ReFi model variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        ReFiType    model,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            model:     model,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, model, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered ReFi term.
     * @param id The term ID.
     * @return model      The ReFi model variant.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ReFiType    model,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.model, t.attack, t.defense, t.timestamp);
    }
}
