// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RevenueParticipationTokenRegistry
 * @notice Defines “Revenue Participation Tokens” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RevenueParticipationTokenRegistry {
    /// @notice Types of revenue participation token structures
    enum RPTType {
        EquityLike,         // tokens representing shares of profit
        DebtLike,           // tokens representing debt obligations
        Hybrid,             // combination of equity and debt features
        NFTBacked,          // NFTs entitling holders to revenue slices
        Fractionalized      // fractional ERC20 slices of a revenue stream
    }

    /// @notice Attack vectors targeting RPT models
    enum AttackType {
        Underreporting,     // issuer hides or understates revenue
        OracleManipulation, // corrupt external price or revenue feeds
        InsiderAbuse,       // insiders divert revenue before distribution
        RegulatoryRisk,     // changes in law invalidate token rights
        ContractBug         // smart contract vulnerability in distribution logic
    }

    /// @notice Defense mechanisms for securing RPT distributions
    enum DefenseType {
        AuditedReports,         // require third-party audits of revenue
        MultiSigOracle,         // multi-sig oracles for revenue feeds
        EscrowedDistributions,  // escrow revenue until consensus confirms
        OnChainAccounting,      // enforce on-chain revenue tracking
        RegulatoryCompliance    // enforce on-chain KYC/AML and legal checks
    }

    struct Term {
        RPTType     rptType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RPTType       rptType,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Revenue Participation Token term.
     * @param rptType  The token structure variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        RPTType     rptType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            rptType:   rptType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, rptType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered RPT term.
     * @param id The term ID.
     * @return rptType   The token structure variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RPTType     rptType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.rptType, t.attack, t.defense, t.timestamp);
    }
}
