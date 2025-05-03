// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RothIRARegistry
 * @notice Defines “Roth IRA” variants along with common
 *         attack vectors (risks) and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RothIRARegistry {
    /// @notice Variants of Roth IRA implementations
    enum RothIRAVariant {
        StandardRoth,       // direct Roth IRA contributions
        BackdoorRoth,       // non-deductible IRA → Roth conversion
        Roth401k,           // employer-sponsored Roth 401(k)
        InheritedRoth,      // Roth IRA inherited from a decedent
        MegaBackdoorRoth    // after-tax 401(k) contributions → Roth
    }

    /// @notice Attack vectors or risks to Roth IRA accounts
    enum AttackType {
        EarlyWithdrawal,    // penalties/taxes on non-qualified distributions
        UnauthorizedAccess, // hacking to drain account
        Misreporting,       // filing incorrect conversion amounts
        Phishing,           // tricking user into revealing credentials
        RegulatoryChange    // tax-law changes reducing benefits
    }

    /// @notice Defense mechanisms or mitigations for Roth IRAs
    enum DefenseType {
        TaxCompliance,      // strict on-chain checks of conversion limits
        TimeLock,           // enforce holding period before withdrawal
        MultiFactorAuth,    // require MFA for sensitive operations
        EncryptedStorage,   // store credentials & data securely
        GovernanceReview    // community/governance review of policy changes
    }

    struct Term {
        RothIRAVariant variant;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed     id,
        RothIRAVariant      variant,
        AttackType          attack,
        DefenseType         defense,
        uint256             timestamp
    );

    /**
     * @notice Register a new Roth IRA term.
     * @param variant  The Roth IRA variant.
     * @param attack   The anticipated attack/risk vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        RothIRAVariant variant,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            variant:   variant,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, variant, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Roth IRA term.
     * @param id The term ID.
     * @return variant   The Roth IRA variant.
     * @return attack    The attack/risk vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RothIRAVariant variant,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.variant, t.attack, t.defense, t.timestamp);
    }
}
