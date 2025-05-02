// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title REKTRegistry
 * @notice Defines “REKT” loss scenarios along with common
 *         attack/causation vectors and defense/mitigation mechanisms.
 *         Users can register and query these combinations on-chain for analysis or governance.
 */
contract REKTRegistry {
    /// @notice Categories of REKT events
    enum REKTType {
        MarketCrash,        // severe price collapse
        Liquidation,        // forced sale due to margin call
        RugPull,            // project team exit scam
        Exploit,            // smart contract hack/theft
        UserError           // user mistake (e.g. wrong address)
    }

    /// @notice Causation/attack vectors leading to REKT
    enum AttackType {
        FlashLiquidation,   // chain reaction liquidity crunch
        GovernanceExploit,  // malicious upgrade or proposal
        OracleHack,         // bad price feed triggers actions
        RugPullMechanism,   // malicious withdraw function
        UIPhishing          // deceptive interface causing user error
    }

    /// @notice Defense/mitigation mechanisms against REKT
    enum DefenseType {
        CircuitBreaker,     // pause trading on extreme moves
        PositionLimits,     // cap leverage and exposure
        MultiSigGuard,      // require multisig for upgrades/withdrawals
        OracleRedundancy,   // aggregate multiple price feeds
        ConfirmationPrompt  // require explicit user confirmations
    }

    struct Term {
        REKTType    rektCategory;
        AttackType  cause;
        DefenseType mitigation;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        REKTType    rektCategory,
        AttackType  cause,
        DefenseType mitigation,
        uint256     timestamp
    );

    /**
     * @notice Register a new REKT term.
     * @param rektCategory The REKT event category.
     * @param cause        The causation/attack vector.
     * @param mitigation   The chosen defense mechanism.
     * @return id          The ID of the newly registered term.
     */
    function registerTerm(
        REKTType    rektCategory,
        AttackType  cause,
        DefenseType mitigation
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            rektCategory: rektCategory,
            cause:        cause,
            mitigation:   mitigation,
            timestamp:    block.timestamp
        });
        emit TermRegistered(id, rektCategory, cause, mitigation, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered REKT term.
     * @param id The term ID.
     * @return rektCategory The REKT event category.
     * @return cause        The causation/attack vector.
     * @return mitigation   The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            REKTType    rektCategory,
            AttackType  cause,
            DefenseType mitigation,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.rektCategory, t.cause, t.mitigation, t.timestamp);
    }
}
