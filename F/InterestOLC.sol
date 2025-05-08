// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Interest‑Bearing On‑Ledger Currency (IOLC)
 * ------------------------------------------
 * • Every holder accrues simple interest at `dailyRateBP`
 *   (basis‑points per day; 1 bp = 0.01 %).
 * • Interest is “lazy”: materialised only when an account
 *   is touched (transfer, mint, burn, or explicit read).
 *
 * NOTE: The token name now uses an ASCII hyphen (`-`)
 * to avoid the parser error caused by the Unicode en‑dash.
 */
contract InterestOLC is ERC20 {
    /// interest rate in basis‑points per day
    uint16 public immutable dailyRateBP;

    struct Snapshot {
        uint256 balance;  // last materialised balance
        uint40  day;      // day number (block.timestamp / 1 day)
    }
    mapping(address => Snapshot) private _snap;

    constructor(uint16 _rateBP)
        ERC20("Interest On-Ledger Currency", "IOLC") // ASCII hyphen ← fixed
    {
        require(_rateBP <= 500, "rate too high");     // ≤ 5 % / day
        dailyRateBP = _rateBP;

        // mint initial supply to deployer (e.g. 1 000 IOLC)
        _mint(msg.sender, 1_000 * 1e18);
    }

    /* ─────── Internal helpers ─────── */

    function _currentDay() private view returns (uint40) {
        return uint40(block.timestamp / 1 days);
    }

    function _accrue(address acct) private {
        Snapshot storage s = _snap[acct];

        // Initialise snapshot if first touch
        if (s.day == 0) {
            s.balance = super.balanceOf(acct);
            s.day     = _currentDay();
            return;
        }

        uint40 today = _currentDay();
        if (today == s.day) return; // already up‑to‑date

        uint256 elapsed = today - s.day;
        uint256 interest = (s.balance * dailyRateBP * elapsed) / 10_000;
        s.balance += interest;  // compound daily
        s.day      = today;
    }

    /* ─────── Public view override ─────── */

    function balanceOf(address acct)
        public
        view
        override
        returns (uint256)
    {
        Snapshot storage s = _snap[acct];
        if (s.day == 0) return super.balanceOf(acct); // never touched

        uint256 elapsed = _currentDay() - s.day;
        uint256 interest = (s.balance * dailyRateBP * elapsed) / 10_000;
        return s.balance + interest;
    }

    /* ─────── Single transfer hook (OZ v5.x) ─────── */

    function _update(address from, address to, uint256 amount)
        internal
        override
    {
        if (from != address(0)) _accrue(from);
        if (to   != address(0)) _accrue(to);

        super._update(from, to, amount);

        // sync snapshots to actual balances after transfer
        if (from != address(0)) _snap[from].balance = super.balanceOf(from);
        if (to   != address(0)) _snap[to].balance   = super.balanceOf(to);
    }
}
