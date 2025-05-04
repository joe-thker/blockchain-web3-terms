// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SecondaryMarketRegistry
 * @notice Defines “Secondary Market” trading venue types along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract SecondaryMarketRegistry {
    /// @notice Types of secondary market venues
    enum MarketType {
        CEX,               // centralized exchange
        DEX,               // decentralized exchange
        OTCDesk,           // over-the-counter desk
        P2PPlatform,       // peer-to-peer trading platform
        AuctionHouse       // on-chain auction mechanism
    }

    /// @notice Attack vectors targeting secondary markets
    enum AttackType {
        FrontRunning,      // MEV or sandwich attacks
        WashTrading,       // artificial volume to manipulate prices
        Spoofing,          // fake orders to mislead market participants
        InsiderLeak,       // leaking order book information
        OracleManipulation // corrupt price feeds used by market
    }

    /// @notice Defense mechanisms for secure secondary markets
    enum DefenseType {
        BatchAuctions,     // batch order matching to prevent frontruns
        CircuitBreakers,   // pause trading on extreme volatility
        RateLimiting,      // throttle order submission rates
        MultiOracleFeeds,  // aggregate oracles for accurate pricing
        OnchainSurveillance // real-time monitoring & flagging of abuse
    }

    struct Term {
        MarketType market;
        AttackType attack;
        DefenseType defense;
        uint256    timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        MarketType     market,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new Secondary Market term.
     * @param market  The secondary market venue type.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id     The ID of the newly registered term.
     */
    function registerTerm(
        MarketType  market,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            market:    market,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, market, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Secondary Market term.
     * @param id The term ID.
     * @return market    The secondary market venue type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            MarketType  market,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.market, t.attack, t.defense, t.timestamp);
    }
}
