// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProfitLossStatementRegistry
 * @notice Defines “Profit & Loss (P&L) Statement” categories along with common
 *         attack vectors and defense mechanisms. Users can register and query
 *         these combinations on-chain for analysis or governance.
 */
contract ProfitLossStatementRegistry {
    /// @notice Types of P&L statements
    enum StatementType {
        SinglePeriod,        // results for one accounting period
        ComparativePeriod,   // side-by-side comparison of two periods
        CommonSizeAnalysis,  // vertical analysis as percentages of revenue
        MultiPeriodTrend,    // trend analysis over multiple periods
        Consolidated         // combined results for a group of entities
    }

    /// @notice Attack vectors targeting P&L reporting
    enum AttackType {
        DataManipulation,     // tampering with figures
        UnauthorizedAccess,   // illicit changes by unauthorized parties
        CalculationError,     // mis-computations or formula mistakes
        FraudulentReporting,  // deliberate mis-statement of results
        ReportingDelay        // withholding or delaying statement publication
    }

    /// @notice Defense mechanisms for P&L integrity
    enum DefenseType {
        AccessControl,       // restrict who can update figures
        AuditTrail,          // record all changes for review
        ImmutableLedger,     // store records in tamper-evident storage
        ValidationChecks,    // automated sanity checks on inputs
        MultiSigApproval     // require multiple approvals before publish
    }

    struct Term {
        StatementType  statement;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        StatementType  statement,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new P&L Statement term.
     * @param statement The P&L statement category.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        StatementType statement,
        AttackType    attack,
        DefenseType   defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            statement: statement,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, statement, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered P&L Statement term.
     * @param id The term ID.
     * @return statement The P&L statement category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            StatementType  statement,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.statement, t.attack, t.defense, t.timestamp);
    }
}
