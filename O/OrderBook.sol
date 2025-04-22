// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OrderBookRegistry
 * @notice Defines “Order Book” models along with common
 *         attack vectors and defense mechanisms. Users can
 *         register and query these combinations on‑chain.
 */
contract OrderBookRegistry {
    /// @notice Types of order book implementations
    enum OrderBookType {
        Centralized,   // order matching on a central server
        Decentralized, // on‑chain order matching (AMM or LOB)
        Hybrid,        // off‑chain order book with on‑chain settlement
        OffChain,      // fully off‑chain book, on‑chain settlement
        OnChain        // fully on‑chain limit order book
    }

    /// @notice Attack vectors targeting order books
    enum AttackType {
        FrontRunning,        // MEV / sandwich around orders
        OrderSpoofing,       // post‑and‑cancel to mislead price
        WashTrading,         // self‑trading to inflate volume
        LatencyManipulation, // exploiting network delays
        SybilAttack          // fake identities to skew order flow
    }

    /// @notice Defense mechanisms for order books
    enum DefenseType {
        TimePriority,        // earliest orders executed first
        OrderBatching,       // batch auctions to prevent MEV
        AntiSpoofing,        // detect and reject rapid cancel‑orders
        RandomizedDelay,     // add slight randomness to execution order
        FeePenalty          // penalize excessive cancellations
    }

    struct OrderBookTerm {
        OrderBookType obType;
        AttackType    attack;
        DefenseType   defense;
        uint256       timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => OrderBookTerm) public terms;

    event OrderBookTermRegistered(
        uint256 indexed id,
        OrderBookType obType,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new Order Book term.
     * @param obType  The order book implementation type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the registered term.
     */
    function registerTerm(
        OrderBookType obType,
        AttackType    attack,
        DefenseType   defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = OrderBookTerm({
            obType:    obType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit OrderBookTermRegistered(id, obType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Order Book term.
     * @param id The term ID.
     * @return obType   The order book type.
     * @return attack   The attack vector.
     * @return defense  The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OrderBookType obType,
            AttackType    attack,
            DefenseType   defense,
            uint256       timestamp
        )
    {
        OrderBookTerm storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.obType, t.attack, t.defense, t.timestamp);
    }
}
