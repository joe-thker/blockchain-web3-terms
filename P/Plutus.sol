// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PlutusRegistry
 * @notice Defines “Plutus” script categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PlutusRegistry {
    /// @notice Types of Plutus scripts and components
    enum PlutusType {
        ValidatorScript,      // on-chain UTXO validation script
        MintingPolicy,        // policy script controlling token mint/burn
        StakeValidator,       // script validating stake/delegation
        OffChainCode,         // off-chain application logic (PAB)
        OracleIntegration     // scripts interacting with oracles
    }

    /// @notice Attack vectors targeting Plutus contracts
    enum AttackType {
        BudgetExhaustion,     // consuming all execution budget
        ScriptInjection,      // inserting malicious script logic
        ReplayAttack,         // replaying old transactions
        OracleManipulation,   // feeding incorrect oracle data
        DenialOfService       // blocking script execution via UTXO spam
    }

    /// @notice Defense mechanisms for Plutus contracts
    enum DefenseType {
        CostModelEnforcement, // enforce strict cost limits on scripts
        FormalVerification,   // mathematically verify script correctness
        InputValidation,      // validate inputs before on-chain use
        TimeLockMechanism,    // enforce time locks on sensitive actions
        OracleRedundancy      // aggregate multiple oracle feeds
    }

    struct Term {
        PlutusType   plutusType;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PlutusType   plutusType,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Plutus term.
     * @param plutusType The Plutus script/category.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        PlutusType  plutusType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            plutusType: plutusType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, plutusType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Plutus term.
     * @param id The term ID.
     * @return plutusType The Plutus script/category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PlutusType  plutusType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.plutusType, t.attack, t.defense, t.timestamp);
    }
}
