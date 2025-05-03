// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ROIRegistry
 * @notice Defines “ROI” (Return on Investment) calculation variants along with common
 *         attack vectors (risks) and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ROIRegistry {
    /// @notice Variants of ROI calculations
    enum ROIType {
        SimplePercentage,     // (gain / cost)×100%
        TimeAdjusted,         // annualized or period-adjusted ROI
        RiskAdjusted,         // ROI adjusted by volatility or drawdown
        IRR,                  // internal rate of return
        NetOfFees            // ROI after accounting for fees/costs
    }

    /// @notice Attack vectors causing misleading ROI figures
    enum AttackType {
        MisleadingReporting,  // cherry-picking gains or costs
        FeeObfuscation,       // hiding or under-declaring fees
        DataManipulation,     // altering historical price or volume data
        TimingManipulation,   // selecting favorable start/end dates
        SurvivorshipBias      // excluding losing investments from calculation
    }

    /// @notice Defense mechanisms to ensure accurate ROI
    enum DefenseType {
        AuditedReports,           // third-party audit of performance data
        TransparentFeeDisclosure, // on-chain record of all fees paid
        OnChainAccounting,        // immutable ledger of trades and costs
        BenchmarkComparison,      // compare ROI against standard indexes
        TimeWeightedReturn       // use TWR to remove cash-flow distortions
    }

    struct Term {
        ROIType    roiCalc;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ROIType        roiCalc,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new ROI term.
     * @param roiCalc The ROI calculation variant.
     * @param attack  The anticipated attack/risk vector.
     * @param defense The chosen defense mechanism.
     * @return id     The ID of the newly registered term.
     */
    function registerTerm(
        ROIType    roiCalc,
        AttackType attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            roiCalc:   roiCalc,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, roiCalc, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered ROI term.
     * @param id The term ID.
     * @return roiCalc   The ROI calculation variant.
     * @return attack    The attack/risk vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ROIType     roiCalc,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.roiCalc, t.attack, t.defense, t.timestamp);
    }
}
