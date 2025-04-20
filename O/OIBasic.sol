// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OpenInterestBasic is Ownable {
    struct Market { string symbol; uint256 longOI; uint256 shortOI; bool exists; }
    uint256 public nextId = 1;
    mapping(uint256 => Market) public mkt;               // id → Market
    mapping(bytes32  => uint256) public idBySym;         // keccak(symbol) → id
    mapping(address  => mapping(uint256 => Position)) public pos;

    struct Position { uint256 size; bool long; }

    event MarketCreated(uint256 id, string symbol);
    event PositionOpened(address indexed t, uint256 id, bool long, uint256 size);
    event PositionClosed(address indexed t, uint256 id, uint256 size);

    constructor() Ownable(msg.sender) {}

    /* ---------- market admin ---------- */
    function addMarket(string calldata sym) external onlyOwner returns (uint256 id) {
        bytes32 h = keccak256(bytes(sym)); require(idBySym[h] == 0, "exists");
        id = nextId++; mkt[id] = Market(sym, 0, 0, true); idBySym[h] = id;
        emit MarketCreated(id, sym);
    }

    /* ---------- open / close ---------- */
    function open(uint256 id, uint256 size, bool long) external {
        require(size > 0 && mkt[id].exists, "bad");
        Position storage p = pos[msg.sender][id];
        if (p.size == 0) p.long = long; else require(p.long == long, "side");
        p.size += size;
        long ? mkt[id].longOI += size : mkt[id].shortOI += size;
        emit PositionOpened(msg.sender, id, long, size);
    }

    function close(uint256 id, uint256 size) external {
        Position storage p = pos[msg.sender][id]; require(p.size >= size && size > 0, "bad");
        p.size -= size;
        p.long ? mkt[id].longOI -= size : mkt[id].shortOI -= size;
        emit PositionClosed(msg.sender, id, size);
    }
}
