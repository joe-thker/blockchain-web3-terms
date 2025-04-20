// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Yield‑Bearing On‑Chain Fiat (YUSD)
 * ────────────────────────────────────────────────────────────
 * • Every account accrues simple interest at `dailyRateBP`
 *   (basis‑points per day; 1 bp = 0.01 %).
 * • Interest is “lazy” – applied when an account is read or touched.
 */
contract YieldFiat is ERC20 {
    uint16 public immutable dailyRateBP;  // interest (bp/day)

    struct Snap { uint256 bal; uint40 day; }
    mapping(address => Snap) private _snap;

    constructor(uint16 rateBp)
        ERC20("Yield On-Chain Fiat USD", "YUSD")
    {
        require(rateBp <= 500, "rate too high"); // ≤5 %/day safety
        dailyRateBP = rateBp;
        _mint(msg.sender, 1_000 * 1e18);         // bootstrap supply
    }

    /* ─────── Helpers ─────── */
    function _today() private view returns (uint40) {
        return uint40(block.timestamp / 1 days);
    }

    function _accrue(address a) private {
        Snap storage s = _snap[a];
        if (s.day == 0) {        // first touch
            s.bal = super.balanceOf(a);
            s.day = _today();
            return;
        }
        uint40 curDay = _today();
        if (curDay == s.day) return;
        uint256 d = curDay - s.day;
        uint256 interest = (s.bal * dailyRateBP * d) / 10_000;
        s.bal += interest;
        s.day  = curDay;
    }

    /* ─────── View override ─────── */
    function balanceOf(address a)
        public view override returns (uint256)
    {
        Snap storage s = _snap[a];
        if (s.day == 0) return super.balanceOf(a);
        uint256 d = _today() - s.day;
        uint256 interest = (s.bal * dailyRateBP * d) / 10_000;
        return s.bal + interest;
    }

    /* ─────── Hook (OZ v5.x) ─────── */
    function _update(address from, address to, uint256 amt)
        internal override
    {
        if (from != address(0)) _accrue(from);
        if (to   != address(0)) _accrue(to);
        super._update(from, to, amt);
        if (from != address(0)) _snap[from].bal = super.balanceOf(from);
        if (to   != address(0)) _snap[to].bal   = super.balanceOf(to);
    }
}
