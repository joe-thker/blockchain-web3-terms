// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title P2PBridgeRegistry
 * @notice Defines “P2P Bridge” types along with common attack vectors
 *         and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract P2PBridgeRegistry {
    /// @notice Types of P2P bridge implementations
    enum BridgeType {
        AtomicSwap,       // direct token swap via hashed timelock
        DepositWithdraw,  // deposit on one chain, withdraw on another
        LiquidityPool,    // pooled liquidity cross-chain
        TrustedCustodian, // centralized custodian handles transfers
        MetaTxRelay       // relayed via meta-transactions
    }

    /// @notice Attack vectors targeting P2P bridges
    enum AttackType {
        DoubleSpend,      // reusing same funds on both chains
        ExitScam,         // custodian absconds with funds
        FrontRunning,     // intercepting and racing transactions
        StateReplay,      // replaying bridge messages illicitly
        FlashLoanAttack   // flash-loan to manipulate bridge collateral
    }

    /// @notice Defense mechanisms for P2P bridges
    enum DefenseType {
        HTLC,             // Hash-Timelock Contracts for atomicity
        MultiSig,         // multi-signature custody of funds
        TimeLock,         // enforced delays before withdrawal
        Collateralization,// over-collateralization to cover losses
        Watchtower        // off-chain watchers to detect fraud
    }

    struct Term {
        BridgeType  bridge;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        BridgeType  bridge,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new P2P Bridge term.
     * @param bridge  The bridge implementation type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the registered term.
     */
    function registerTerm(
        BridgeType  bridge,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            bridge:    bridge,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, bridge, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered P2P Bridge term.
     * @param id The term ID.
     * @return bridge   The bridge type.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            BridgeType  bridge,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.bridge, t.attack, t.defense, t.timestamp);
    }
}
