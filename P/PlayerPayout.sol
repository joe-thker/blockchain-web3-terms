// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PlayerPayoutRegistry
 * @notice Defines “Player Payout” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PlayerPayoutRegistry {
    /// @notice Types of player payouts
    enum PlayerPayoutType {
        FixedReward,       // predetermined payout per action
        VariableReward,    // payout based on performance metrics
        TournamentPrize,   // prize distribution for competitions
        ReferralBonus,     // bonus for referring new players
        StakingReward      // rewards from staking in-game assets
    }

    /// @notice Attack vectors targeting payout mechanisms
    enum AttackType {
        FraudulentClaim,      // fake or duplicated payout requests
        FlashLoanExploit,     // use flash loans to manipulate payout logic
        OracleManipulation,   // feeding incorrect data for variable payouts
        Reentrancy,           // exploiting contract reentrancy to drain funds
        DOSAttack             // denial-of-service to block legitimate payouts
    }

    /// @notice Defense mechanisms to secure payouts
    enum DefenseType {
        KYCVerification,      // verify user identity before payouts
        RateLimiting,         // throttle frequency or size of payouts
        OracleRedundancy,     // aggregate multiple data sources
        ReentrancyGuard,      // prevent reentrant calls in payout functions
        CircuitBreaker        // emergency pause of payouts under duress
    }

    struct Term {
        PlayerPayoutType payoutType;
        AttackType       attack;
        DefenseType      defense;
        uint256          timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PlayerPayoutType payoutType,
        AttackType       attack,
        DefenseType      defense,
        uint256          timestamp
    );

    /**
     * @notice Register a new Player Payout term.
     * @param payoutType The payout category.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        PlayerPayoutType payoutType,
        AttackType       attack,
        DefenseType      defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            payoutType: payoutType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, payoutType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return payoutType The payout category.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PlayerPayoutType payoutType,
            AttackType       attack,
            DefenseType      defense,
            uint256          timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.payoutType, t.attack, t.defense, t.timestamp);
    }
}
