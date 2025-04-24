// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PeggedCurrencyRegistry
 * @notice Defines “Pegged Currency” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PeggedCurrencyRegistry {
    /// @notice Types of pegged currencies
    enum PeggedCurrencyType {
        FiatPegged,            // 1:1 peg to a fiat currency (e.g. USDC)
        CryptoCollateralized,  // backed by other crypto assets (e.g. WBTC)
        Algorithmic,           // uses supply adjustments to maintain peg
        MultiAsset,            // backed by a basket of assets
        SeigniorageShares      // uses algorithmic bonds & shares
    }

    /// @notice Attack vectors targeting pegged currencies
    enum AttackType {
        OracleManipulation,   // feeding incorrect price data
        ReserveRunoff,        // draining collateral reserves
        GovernanceCapture,    // hijacking upgrade/governance process
        BlackSwanShock,       // extreme market events breaking peg
        FlashLoanAttack       // flash loan to destabilize collateral
    }

    /// @notice Defense mechanisms for pegged currencies
    enum DefenseType {
        OverCollateralization, // hold excess collateral buffer
        CircuitBreaker,        // pause mint/redemptions under stress
        OracleRedundancy,      // aggregate multiple independent feeds
        ReserveAuditing,       // on-chain proof of reserves
        GovernanceTimelock     // enforce delay on protocol changes
    }

    struct Term {
        PeggedCurrencyType currencyType;
        AttackType         attack;
        DefenseType        defense;
        uint256            timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event PeggedCurrencyTermRegistered(
        uint256 indexed id,
        PeggedCurrencyType currencyType,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Pegged Currency term.
     * @param currencyType The pegged currency category.
     * @param attack       The anticipated attack vector.
     * @param defense      The chosen defense mechanism.
     * @return id          The ID of the newly registered term.
     */
    function registerTerm(
        PeggedCurrencyType currencyType,
        AttackType         attack,
        DefenseType        defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            currencyType: currencyType,
            attack:       attack,
            defense:      defense,
            timestamp:    block.timestamp
        });
        emit PeggedCurrencyTermRegistered(
            id,
            currencyType,
            attack,
            defense,
            block.timestamp
        );
    }

    /**
     * @notice Retrieve details of a registered Pegged Currency term.
     * @param id The term ID.
     * @return currencyType The pegged currency category.
     * @return attack       The attack vector.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PeggedCurrencyType currencyType,
            AttackType         attack,
            DefenseType        defense,
            uint256            timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (
            t.currencyType,
            t.attack,
            t.defense,
            t.timestamp
        );
    }
}
