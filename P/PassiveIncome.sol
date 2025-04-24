// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PassiveIncomeRegistry
 * @notice Defines “Passive Income” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PassiveIncomeRegistry {
    /// @notice Types of passive income strategies
    enum PassiveIncomeType {
        Staking,           // locking tokens to earn rewards
        Lending,           // lending assets for interest
        YieldFarming,      // providing liquidity to farm rewards
        LiquidityMining,   // earning protocol tokens for LP
        Dividend           // receiving dividends from holdings
    }

    /// @notice Attack vectors targeting passive income
    enum AttackType {
        RugPull,           // project withdraws liquidity or funds
        SmartContractExploit, // vulnerability in protocol code
        OracleManipulation,   // feeding incorrect price data
        ImpermanentLoss,      // losses due to price divergence
        FlashLoanAttack       // flash-loan to drain funds
    }

    /// @notice Defense mechanisms for passive income strategies
    enum DefenseType {
        Audit,             // third-party security audit
        MultiSig,          // multi-signature withdrawals
        TimeLock,          // delayed withdrawals via timelock
        Insurance,         // coverage via on-chain insurance funds
        CollateralBuffer   // extra collateral to absorb losses
    }

    struct Term {
        PassiveIncomeType incomeType;
        AttackType        attack;
        DefenseType       defense;
        uint256           timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PassiveIncomeType incomeType,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new Passive Income term.
     * @param incomeType The category of passive income.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        PassiveIncomeType incomeType,
        AttackType        attack,
        DefenseType       defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            incomeType: incomeType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, incomeType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return incomeType The passive income category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PassiveIncomeType incomeType,
            AttackType        attack,
            DefenseType       defense,
            uint256           timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.incomeType, t.attack, t.defense, t.timestamp);
    }
}
