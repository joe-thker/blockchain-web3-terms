// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SecurityRegistry
 * @notice Defines “Security” (financial instruments) categories along with common
 *         attack vectors (risks) and defense mechanisms (safeguards). Users can
 *         register and query these combinations on-chain for analysis or governance.
 */
contract SecurityRegistry {
    /// @notice Types of financial securities
    enum SecurityType {
        Equity,           // shares of ownership (stocks)
        Debt,             // bonds or notes representing loan
        Derivative,       // options, futures, swaps
        Fund,             // mutual funds, ETFs
        Hybrid            // convertible bonds, preferred shares
    }

    /// @notice Risk vectors associated with securities
    enum RiskType {
        MarketRisk,       // price volatility risk
        CreditRisk,       // issuer default risk
        LiquidityRisk,    // inability to buy/sell without price impact
        CounterpartyRisk, // risk the other party defaults
        OperationalRisk   // failures in processes or systems
    }

    /// @notice Safeguards to mitigate security risks
    enum DefenseType {
        Diversification,      // spread investments across assets
        CreditAnalysis,       // evaluate issuer creditworthiness
        MarketMaking,         // provide liquidity support
        ClearingHouseGuarantee, // use CCP to manage counterparty risk
        RegulatoryCompliance  // adhere to securities regulations
    }

    struct Term {
        SecurityType security;
        RiskType     risk;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed  id,
        SecurityType     security,
        RiskType         risk,
        DefenseType      defense,
        uint256          timestamp
    );

    /**
     * @notice Register a new Security term.
     * @param security The financial security category.
     * @param risk     The associated risk vector.
     * @param defense  The chosen safeguard mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        SecurityType security,
        RiskType     risk,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            security:  security,
            risk:      risk,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, security, risk, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Security term.
     * @param id The term ID.
     * @return security  The financial security category.
     * @return risk      The associated risk vector.
     * @return defense   The chosen safeguard mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            SecurityType security,
            RiskType     risk,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.security, t.risk, t.defense, t.timestamp);
    }
}
