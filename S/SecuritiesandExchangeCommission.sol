// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SECRegistry
 * @notice Defines “Securities and Exchange Commission (SEC)” oversight types along with common
 *         attack vectors (regulatory risks) and defense mechanisms (compliance measures). Users can
 *         register and query these combinations on-chain for analysis or governance.
 */
contract SECRegistry {
    /// @notice Types of SEC oversight functions
    enum OversightType {
        RegistrationReview,    // reviewing registration statements
        EnforcementAction,     // pursuing enforcement against violations
        MarketSurveillance,    // monitoring market activity for fraud
        Rulemaking,            // creating or updating regulations
        DisclosureRequirement  // mandating periodic disclosures
    }

    /// @notice Attack vectors or risks under SEC oversight
    enum RiskType {
        FraudulentReporting,   // false or misleading financial statements
        InsiderTrading,        // illicit trading on non-public information
        MarketManipulation,    // pump-and-dump or spoofing schemes
        NonCompliance,         // failing to adhere to SEC rules
        DataSecurityBreach     // unauthorized leak of sensitive filings
    }

    /// @notice Compliance mechanisms to satisfy SEC requirements
    enum DefenseType {
        AuditCertification,    // third-party audit of financials
        InsiderTradingPolicies,// strict policies and monitoring controls
        SurveillanceTech,      // on-chain monitoring tools for market abuse
        AutomatedFilings,      // programmatic generation/submission of reports
        DataEncryption         // encrypt sensitive data in disclosures
    }

    struct Term {
        OversightType oversight;
        RiskType      risk;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        OversightType      oversight,
        RiskType           risk,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new SEC term.
     * @param oversight The SEC oversight function.
     * @param risk      The regulatory risk or attack vector.
     * @param defense   The chosen compliance mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        OversightType oversight,
        RiskType      risk,
        DefenseType   defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            oversight: oversight,
            risk:      risk,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, oversight, risk, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered SEC term.
     * @param id The term ID.
     * @return oversight The SEC oversight function.
     * @return risk      The regulatory risk.
     * @return defense   The compliance mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OversightType oversight,
            RiskType      risk,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.oversight, t.risk, t.defense, t.timestamp);
    }
}
