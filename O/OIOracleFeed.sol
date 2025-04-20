// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * OpenInterestOracleFeed
 * ------------------------------------------------
 *  Off‑chain oracle (or keeper bot) periodically pushes
 *  open‑interest numbers for a given market symbol.
 *
 *  FIX: Added `constructor() Ownable(msg.sender)` so the
 *  OpenZeppelin Ownable base constructor receives the
 *  required `initialOwner` argument, removing the
 *  “No arguments passed to the base constructor” error.
 */
contract OpenInterestOracleFeed is Ownable {
    struct OIData {
        uint256 longOI;   // total open long size
        uint256 shortOI;  // total open short size
        uint256 updated;  // timestamp of last push
    }

    mapping(string => OIData) public data;   // symbol -> OI record

    event Posted(string indexed symbol, uint256 longOI, uint256 shortOI);

    /* ---------------- constructor (FIX) ---------------- */
    constructor() Ownable(msg.sender) {}

    /* ---------------- oracle push ---------------- */
    function post(
        string calldata symbol,
        uint256 longOI,
        uint256 shortOI
    ) external onlyOwner {
        data[symbol] = OIData(longOI, shortOI, block.timestamp);
        emit Posted(symbol, longOI, shortOI);
    }

    /* ---------------- view helper ---------------- */
    function get(string calldata symbol)
        external
        view
        returns (uint256 longOI, uint256 shortOI, uint256 timestamp)
    {
        OIData storage d = data[symbol];
        return (d.longOI, d.shortOI, d.updated);
    }
}
