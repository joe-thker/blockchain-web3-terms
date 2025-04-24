// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title P2PLendingRegistry
 * @notice Defines “Peer-to-Peer (P2P) Lending” categories along with
 *         common attack vectors and defense mechanisms. Users can
 *         register and query these combinations on-chain for analysis
 *         or governance.
 */
contract P2PLendingRegistry {
    /// @notice Types of P2P lending models
    enum LendingType {
        Unsecured,          // loans without collateral
        Secured,            // loans backed by collateral
        PoolBased,          // borrowers draw from a liquidity pool
        SocialLending,      // loans within social/trust groups
        FlashLoan           // uncollateralized, same-transaction loans
    }

    /// @notice Attack vectors targeting P2P lending
    enum AttackType {
        DefaultRisk,        // borrower fails to repay
        OracleManipulation, // feeding wrong price data for collateral
        SybilAttack,        // fake identities to borrow repeatedly
        FlashLoanExploit,   // using flash loans to manipulate pools
        CollateralSeizure   // unauthorized seizure of collateral
    }

    /// @notice Defense mechanisms for P2P lending
    enum DefenseType {
        CollateralRequirement, // enforce sufficient collateral ratios
        ReputationSystem,      // credit scoring based on past behavior
        OracleRedundancy,      // multiple price oracles for safety
        InsurancePool,         // pooled insurance against defaults
        KYC                    // identity verification of participants
    }

    struct Term {
        LendingType lending;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        LendingType lending,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new P2P Lending term.
     * @param lending The P2P lending model type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        LendingType lending,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            lending:   lending,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, lending, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered P2P Lending term.
     * @param id The term ID.
     * @return lending  The P2P lending model type.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            LendingType lending,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.lending, t.attack, t.defense, t.timestamp);
    }
}
