// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OverCollateralizationRegistry
 * @notice Defines categories of Over-Collateralization schemes along with
 *         common attack vectors and defense mechanisms. Users can
 *         register and query these combinations on-chain for analysis
 *         or governance.
 */
contract OverCollateralizationRegistry {
    /// @notice Types of over-collateralization implementations
    enum OverCollateralizationType {
        SingleAsset,     // collateralized with one asset (e.g. ETH)
        MultiAsset,      // collateralized with a basket of assets
        DynamicRatio,    // collateral ratio adjusts based on risk
        PooledCollateral,// pooled collateral from multiple participants
        CrossChain       // collateral bridged from another chain
    }

    /// @notice Attack vectors targeting over-collateralized positions
    enum AttackType {
        OracleManipulation,   // feeding wrong price data to undervalue collateral
        LiquidationSpam,      // spamming liquidations to manipulate prices
        FlashLoanLoop,        // using flash loans to exploit collateral loops
        CollateralSeizure,    // unauthorized seizure of collateral
        Censorship            // blocking liquidation transactions
    }

    /// @notice Defense mechanisms for over-collateralization schemes
    enum DefenseType {
        OracleRedundancy,     // multiple independent price feeds
        CollateralBuffer,     // extra safety margin above minimum ratio
        AuctionLiquidation,   // fair auction mechanism on liquidate
        CircuitBreaker,       // pause liquidations under stress
        RateLimiter           // limit frequency/volume of liquidations
    }

    struct Term {
        OverCollateralizationType ocType;
        AttackType                attack;
        DefenseType               defense;
        uint256                   timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        OverCollateralizationType ocType,
        AttackType                attack,
        DefenseType               defense,
        uint256                   timestamp
    );

    /**
     * @notice Register a new Over-Collateralization term.
     * @param ocType  The implementation category.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the registered term.
     */
    function registerTerm(
        OverCollateralizationType ocType,
        AttackType                attack,
        DefenseType               defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            ocType:    ocType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, ocType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return ocType    The over-collateralization category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OverCollateralizationType ocType,
            AttackType                attack,
            DefenseType               defense,
            uint256                   timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.ocType, t.attack, t.defense, t.timestamp);
    }
}
