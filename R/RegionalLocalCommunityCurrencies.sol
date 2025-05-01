// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RegionalCurrencyRegistry
 * @notice Defines “Regional/Local/Community Currencies” categories along with common
 *         attack vectors and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract RegionalCurrencyRegistry {
    /// @notice Types of regional/local/community currencies
    enum CurrencyType {
        LocalCurrency,         // currency backed and issued by a town or region
        CommunityCurrency,     // issued and managed by a specific community
        MutualCredit,          // credit-based, balances out across participants
        TimeBank,              // hours of service exchanged as currency
        ComplementaryCurrency  // parallel currency alongside national currency
    }

    /// @notice Attack vectors targeting community currencies
    enum AttackType {
        Devaluation,           // loss of trust reduces currency value
        FraudulentIssuance,    // illicit creation of extra units
        DoubleSpending,        // spending same units twice
        RegulatoryClampdown,   // legal restrictions halting use
        Inflation              // uncontrolled increase in supply
    }

    /// @notice Defense mechanisms for securing community currencies
    enum DefenseType {
        PeggingMechanism,      // peg to a stable asset or index
        TransparentAudits,     // regular public audits of issuance and supply
        ReserveBacking,        // collateral reserves to back units
        CommunityGovernance,   // on-chain votes for issuance parameters
        SmartContractLimits    // max issuance and transfer limits enforced by code
    }

    struct Term {
        CurrencyType currencyType;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed   id,
        CurrencyType      currencyType,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new Regional/Local/Community Currency term.
     * @param currencyType  The currency category.
     * @param attack        The anticipated attack vector.
     * @param defense       The chosen defense mechanism.
     * @return id           The ID of the newly registered term.
     */
    function registerTerm(
        CurrencyType currencyType,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            currencyType: currencyType,
            attack:       attack,
            defense:      defense,
            timestamp:    block.timestamp
        });
        emit TermRegistered(id, currencyType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered currency term.
     * @param id The term ID.
     * @return currencyType The currency category.
     * @return attack       The attack vector.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            CurrencyType currencyType,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.currencyType, t.attack, t.defense, t.timestamp);
    }
}
