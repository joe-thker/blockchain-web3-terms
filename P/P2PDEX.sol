// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title P2PDEXRegistry
 * @notice Defines “P2P DEX” models along with common attack vectors
 *         and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract P2PDEXRegistry {
    /// @notice Types of peer-to-peer DEX architectures
    enum P2PDEXType {
        LimitOrderBook,      // on-chain limit orders matched by smart contracts
        RequestForQuote,     // off-chain RFQ with on-chain settlement
        AtomicSwap,          // direct token swaps via HTLC
        HybridModel,         // combination of on/off-chain order matching
        LiquidityPoolReplay  // LPs that replay on-chain orders peer-to-peer
    }

    /// @notice Attack vectors targeting P2P DEXes
    enum AttackType {
        FrontRunning,        // MEV sandwich attacks on pending orders
        OrderSpoofing,       // placing and cancelling orders to mislead
        OracleManipulation,  // feeding bad price data to oracles
        FlashLoanExploit,    // using flash loans to manipulate order books
        DenialOfService      // spamming orders to congest the matching engine
    }

    /// @notice Defense mechanisms for P2P DEXes
    enum DefenseType {
        BatchAuction,        // group orders into discrete auctions to prevent MEV
        CommitReveal,        // hide orders until commit phase ends
        SlippageControl,     // enforce maximum slippage on fills
        MEVShield,           // use MEV-protection relayers or protected pools
        OracleRedundancy     // aggregate multiple price oracles for safety
    }

    struct Term {
        P2PDEXType  dexType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        P2PDEXType  dexType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new P2P DEX term.
     * @param dexType  The P2P DEX architecture type.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        P2PDEXType  dexType,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            dexType:   dexType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, dexType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered P2P DEX term.
     * @param id The term ID.
     * @return dexType  The P2P DEX architecture.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            P2PDEXType  dexType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.dexType, t.attack, t.defense, t.timestamp);
    }
}
