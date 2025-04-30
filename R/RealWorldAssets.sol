// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RealWorldAssetsRegistry
 * @notice Defines “Real World Assets (RWAs)” categories along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RealWorldAssetsRegistry {
    /// @notice Types of tokenized real-world assets
    enum RWAType {
        TokenizedRealEstate,  // property-backed tokens
        Commodities,          // gold, oil, agricultural commodities
        ArtNFTs,              // fractionalized art ownership NFTs
        DebtInstruments,      // tokenized bonds or receivables
        Collectibles          // rare items, memorabilia
    }

    /// @notice Attack vectors targeting RWAs
    enum AttackType {
        ValuationManipulation, // false appraisals or price feeds
        CustodyRisk,           // theft or loss of underlying asset
        ComplianceFailure,     // failure to meet legal/KYC requirements
        LiquidationRisk,       // forced sale at unfavorable prices
        OracleManipulation     // feeding incorrect off-chain data
    }

    /// @notice Defense mechanisms for securing RWAs
    enum DefenseType {
        AuditedValuations,     // third-party verified appraisals
        CustodyInsurance,      // insured storage or custodial coverage
        RegulatoryCompliance,  // on-chain KYC/AML and legal adherence
        MultiOraclePriceFeed,  // aggregate multiple reliable oracles
        LiquidityReserves      // maintain reserve buffer for redemptions
    }

    struct Term {
        RWAType     rwaType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RWAType     rwaType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Real World Asset term.
     * @param rwaType  The RWA category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        RWAType     rwaType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            rwaType:   rwaType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, rwaType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered RWA term.
     * @param id The term ID.
     * @return rwaType   The RWA category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RWAType     rwaType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.rwaType, t.attack, t.defense, t.timestamp);
    }
}
