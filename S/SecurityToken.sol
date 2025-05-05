// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SecurityTokenRegistry
 * @notice Defines “Security Token” models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract SecurityTokenRegistry {
    /// @notice Variants of security tokens
    enum TokenModel {
        EquityToken,        // represents shares in an issuer
        DebtToken,          // bond-like debt obligations
        RevenueShareToken,  // entitles holder to revenue share
        AssetBackedToken,   // collateralized by real-world assets
        HybridToken         // combines features of multiple models
    }

    /// @notice Attack vectors targeting security tokens
    enum AttackType {
        UnauthorizedMint,   // minting tokens without permission
        TransferBypass,     // evading transfer restrictions
        OracleManipulation, // corrupting price or compliance oracles
        InsiderDump,        // insiders dumping tokens for profit
        RegulatoryEvasion   // exploiting loopholes in token rules
    }

    /// @notice Defense mechanisms for security tokens
    enum DefenseType {
        RoleBasedMinting,   // restrict minting to authorized roles
        TransferHooks,      // enforce on-chain transfer checks
        MultiOracleChecks,  // require multiple oracle confirmations
        VestingSchedules,   // lock tokens to prevent immediate dump
        ComplianceModule    // integrated on-chain KYC/AML checks
    }

    struct Term {
        TokenModel   model;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        TokenModel   model,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Security Token term.
     * @param model    The token model variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        TokenModel   model,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            model:     model,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, model, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Security Token term.
     * @param id The term ID.
     * @return model      The token model variant.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            TokenModel  model,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.model, t.attack, t.defense, t.timestamp);
    }
}
