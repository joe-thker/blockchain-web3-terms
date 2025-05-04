// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SecureAssetFundRegistry
 * @notice Defines “Secure Asset Fund for Users” (SAFU) fund types along with 
 *         common attack vectors and defense mechanisms. Users can register and 
 *         query these combinations on-chain for analysis or governance.
 */
contract SecureAssetFundRegistry {
    /// @notice Types of SAFU funding models
    enum FundType {
        ExchangeReserve,    // centralized exchange’s emergency reserve fund
        InsurancePool,      // pooled insurance contributions from users
        DecentralizedDAO,   // community-governed risk mitigation DAO
        StakingBuffer,      // protocol staking set aside for losses
        CrossChainGuard     // multi-chain guard fund for bridge losses
    }

    /// @notice Attack vectors threatening SAFU pools
    enum AttackType {
        ExchangeHack,        // breach of exchange hot wallets
        OracleManipulation,  // false insurance triggers via price oracles
        GovernanceExploit,   // takeover of DAO voting to drain funds
        FlashLoanAttack,     // rapid loan to trigger fund drain logic
        BridgeExploit        // attack on cross-chain bridge drains guard
    }

    /// @notice Defense mechanisms securing SAFU pools
    enum DefenseType {
        MultiSigTreasury,    // require multiple signatures for withdrawals
        MultiOracleChecks,   // require multiple oracles for insurance claims
        TimelockedVoting,    // enforce timelocks on DAO withdrawals
        RateLimiting,        // cap claim size per time window
        AuditedBridges       // audited contracts for cross-chain security
    }

    struct Term {
        FundType    fundModel;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        FundType    fundModel,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new SAFU term.
     * @param fundModel The SAFU funding model.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        FundType    fundModel,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            fundModel: fundModel,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, fundModel, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered SAFU term.
     * @param id The term ID.
     * @return fundModel The SAFU funding model.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            FundType    fundModel,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.fundModel, t.attack, t.defense, t.timestamp);
    }
}
