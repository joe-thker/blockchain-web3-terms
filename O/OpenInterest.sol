// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * OpenInterestTracker
 * ------------------------------------------------------------------
 * • Allows the owner to list trading markets (e.g., BTC‑PERP, ETH‑PERP).
 * • Traders open / close long or short positions.
 * • Contract maintains the current open interest (OI) on each side.
 *
 * NOTE
 * ----
 * This is a metrics contract only.  It does NOT handle margin,
 * funding, or liquidation logic.  Integrate it with your perp
 * engine or use it as an on‑chain oracle of OI statistics.
 */
contract OpenInterestTracker is Ownable {
    /* ------------------------- Market data ------------------------- */
    struct Market {
        string  symbol;          // human‑readable, e.g. "BTC‑PERP"
        uint256 longOI;          // sum of open long position sizes
        uint256 shortOI;         // sum of open short position sizes
        bool    exists;
    }

    /* ---------------------- Storage mappings ----------------------- */
    uint256 public nextMarketId = 1;
    mapping(uint256 => Market)        public markets;      // id -> market
    mapping(bytes32  => uint256)      public idBySymbol;   // keccak256(symbol) -> id
    mapping(address  => mapping(uint256 => Position)) public positions;

    struct Position {
        uint256 size;  // positive value
        bool    isLong;
    }

    /* --------------------------- Events ---------------------------- */
    event MarketCreated(uint256 indexed id, string symbol);
    event PositionOpened(address indexed trader, uint256 indexed id, bool isLong, uint256 size);
    event PositionClosed(address indexed trader, uint256 indexed id, bool isLong, uint256 size);

    /* ------------------------ Market admin ------------------------- */
    constructor() Ownable(msg.sender) {}

    function createMarket(string calldata symbol) external onlyOwner returns (uint256 id) {
        require(bytes(symbol).length > 0, "empty symbol");

        bytes32 hash = keccak256(bytes(symbol));
        require(idBySymbol[hash] == 0, "exists");

        id = nextMarketId++;
        markets[id] = Market({symbol: symbol, longOI: 0, shortOI: 0, exists: true});
        idBySymbol[hash] = id;

        emit MarketCreated(id, symbol);
    }

    /* ------------------- Trader position actions ------------------- */

    /**
     * @notice Open (or add to) a position.
     * @param id    Market id.
     * @param size  Position size (e.g., contract size or USD value).
     * @param isLong true = long, false = short.
     */
    function openPosition(uint256 id, uint256 size, bool isLong) external {
        require(size > 0, "size zero");
        Market storage m = markets[id];
        require(m.exists, "bad market");

        Position storage p = positions[msg.sender][id];
        if (p.size == 0) {
            p.isLong = isLong; // first time sets side
        } else {
            require(p.isLong == isLong, "side mismatch");
        }

        p.size += size;
        if (isLong) {
            m.longOI += size;
        } else {
            m.shortOI += size;
        }
        emit PositionOpened(msg.sender, id, isLong, size);
    }

    /**
     * @notice Reduce or close an existing position.
     * @param id    Market id.
     * @param size  Amount to close.
     */
    function closePosition(uint256 id, uint256 size) external {
        require(size > 0, "size zero");
        Market storage m = markets[id];
        require(m.exists, "bad market");

        Position storage p = positions[msg.sender][id];
        require(p.size >= size, "too much");

        p.size -= size;
        if (p.isLong) {
            m.longOI -= size;
        } else {
            m.shortOI -= size;
        }
        emit PositionClosed(msg.sender, id, p.isLong, size);
    }

    /* ----------------------- View functions ------------------------ */
    function openInterest(uint256 id)
        external
        view
        returns (uint256 longOI, uint256 shortOI)
    {
        Market storage m = markets[id];
        require(m.exists, "bad market");
        return (m.longOI, m.shortOI);
    }

    function marketId(string calldata symbol) external view returns (uint256) {
        return idBySymbol[keccak256(bytes(symbol))];
    }
}
