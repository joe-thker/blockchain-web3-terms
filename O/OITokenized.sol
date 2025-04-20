// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* -------------------------------------------------------------------------- */
/*                      Tokenised Open‑Interest (OI) v1                       */
/* -------------------------------------------------------------------------- */
/*
   Each market has its own pair of ERC‑20 tokens:

        •  LONG‑<symbol>  – represents long open‑interest units
        •  SHORT‑<symbol> – represents short open‑interest units

   A trader “opens” OI by minting the corresponding token and “closes”
   by burning it.  Total supply of each side always equals the live OI.

   This file fixes the previous parser error:
     `struct Long  is ERC20`  → must be `contract LongOI is ERC20`.

   Both `LongOI` and `ShortOI` are defined as inner contracts, then
   deployed with `new LongOI(symbol)` and `new ShortOI(symbol)`.
*/

/* ─────────────────────────  OI receipt tokens  ─────────────────────────── */
contract LongOI is ERC20 {
    constructor(string memory symbol_)
        ERC20(
            string.concat(symbol_, " LONG OI"),
            string.concat("LONG", symbol_)
        )
    {}
}

contract ShortOI is ERC20 {
    constructor(string memory symbol_)
        ERC20(
            string.concat(symbol_, " SHORT OI"),
            string.concat("SHORT", symbol_)
        )
    {}
}

/* ──────────────────────────  Registry contract  ────────────────────────── */
contract TokenisedOpenInterest is Ownable {
    struct Market {
        string  symbol;
        LongOI  longToken;
        ShortOI shortToken;
        bool    exists;
    }

    uint256 public nextId = 1;
    mapping(uint256  => Market) public markets;      // id → Market
    mapping(bytes32  => uint256) public idBySymbol;  // keccak(symbol) → id

    event MarketCreated(uint256 indexed id, address longToken, address shortToken);

    constructor() Ownable(msg.sender) {}

    /* -------- owner adds new market -------- */
    function addMarket(string calldata symbol) external onlyOwner returns (uint256 id) {
        require(bytes(symbol).length > 0, "empty symbol");
        bytes32 hash = keccak256(bytes(symbol));
        require(idBySymbol[hash] == 0, "symbol exists");

        LongOI  longTok  = new LongOI(symbol);
        ShortOI shortTok = new ShortOI(symbol);

        id = nextId++;
        markets[id] = Market(symbol, longTok, shortTok, true);
        idBySymbol[hash] = id;

        emit MarketCreated(id, address(longTok), address(shortTok));
    }

    /* -------- convenience views -------- */
    function tokens(uint256 id) external view returns (address longToken, address shortToken) {
        Market storage m = markets[id];
        require(m.exists, "bad id");
        return (address(m.longToken), address(m.shortToken));
    }

    function openInterest(uint256 id) external view returns (uint256 longOI, uint256 shortOI) {
        Market storage m = markets[id];
        require(m.exists, "bad id");
        return (m.longToken.totalSupply(), m.shortToken.totalSupply());
    }
}
