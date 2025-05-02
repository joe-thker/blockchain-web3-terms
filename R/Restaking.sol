// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RestakingRegistry
 * @notice Defines “Restaking” models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RestakingRegistry {
    /// @notice Types of restaking models
    enum RestakeType {
        DirectRestake,      // directly restake rewards into same protocol
        LiquidRestake,      // use liquid staking tokens to restake elsewhere
        CrossChainRestake,  // move staking positions across chains
        AutoCompound,       // protocol automatically compounds rewards
        DelegatedRestake    // delegate restake operations to a service
    }

    /// @notice Attack vectors targeting restaking strategies
    enum AttackType {
        OracleManipulation, // corrupt price or reward oracles
        FlashLoanDrain,     // use flash loans to manipulate liquidity before restake
        LiquidationRisk,    // restaked collateral gets liquidated
        SlippageAttack,     // high slippage during restake transactions
        GovernanceExploit   // malicious parameter change in restake logic
    }

    /// @notice Defense mechanisms for secure restaking
    enum DefenseType {
        MultiOracleFeeds,   // aggregate multiple oracles for accurate rewards/prices
        SlippageLimits,     // cap allowed slippage per restake
        LiquidationBuffers, // maintain extra collateral buffer to avoid liquidations
        TimelockedRestake,  // delay restake operations to allow intervention
        GovernanceTimelock  // timelock for protocol parameter changes
    }

    struct Term {
        RestakeType restakeModel;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RestakeType  restakeModel,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Restaking term.
     * @param restakeModel The restaking model variant.
     * @param attack       The anticipated attack vector.
     * @param defense      The chosen defense mechanism.
     * @return id          The ID of the newly registered term.
     */
    function registerTerm(
        RestakeType restakeModel,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            restakeModel: restakeModel,
            attack:       attack,
            defense:      defense,
            timestamp:    block.timestamp
        });
        emit TermRegistered(id, restakeModel, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Restaking term.
     * @param id The term ID.
     * @return restakeModel The restaking model variant.
     * @return attack       The attack vector.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RestakeType restakeModel,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.restakeModel, t.attack, t.defense, t.timestamp);
    }
}
