// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";  // ← correct interface
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Permit‑Based OCO Router (no custody)
 * ------------------------------------
 * • Trader signs an EIP‑2612 permit; tokens stay in their wallet.
 * • Executor calls `fillTP` or `fillSL`; router pulls tokens via permit.
 * • First side executed cancels the other (“one cancels the other”).
 */
contract PermitOCORouter {
    using SafeERC20 for IERC20;

    struct Order {
        address        trader;
        IERC20Permit   asset;     // ← FIX: now IERC20Permit
        IERC20         quote;
        uint256        amount;
        uint256        tp;        // take‑profit (1e18 quote/asset)
        uint256        sl;        // stop‑loss   (1e18 quote/asset)
        address        router;    // DEX router for swap
        uint256        deadline;  // permit deadline
        uint8          v; bytes32 r; bytes32 s;  // signature
        bool           executed;
        bool           cancelled;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Order) public orders;

    event Placed   (uint256 id, address trader);
    event FilledTP (uint256 id, uint256 price, address executor);
    event FilledSL (uint256 id, uint256 price, address executor);
    event Cancelled(uint256 id);

    /* ─────────────────── Place order ─────────────────── */
    function place(
        IERC20Permit asset,
        IERC20  quote,
        uint256 amount,
        uint256 tp,
        uint256 sl,
        address router,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 id) {
        require(amount > 0, "zero amount");
        require(tp > sl,    "tp <= sl");
        require(router != address(0), "router 0");

        id = nextId++;
        orders[id] = Order({
            trader: msg.sender,
            asset:  asset,
            quote:  quote,
            amount: amount,
            tp:     tp,
            sl:     sl,
            router: router,
            deadline: deadline,
            v: v, r: r, s: s,
            executed: false,
            cancelled: false
        });

        emit Placed(id, msg.sender);
    }

    /* ─────────────────── Execution ─────────────────── */

    function fillTP(uint256 id, uint256 price) external {
        Order storage o = orders[id];
        _active(o);
        require(price >= o.tp, "price < TP");
        _pullAndForward(o);
        o.executed = true;
        emit FilledTP(id, price, msg.sender);
    }

    function fillSL(uint256 id, uint256 price) external {
        Order storage o = orders[id];
        _active(o);
        require(price <= o.sl, "price > SL");
        _pullAndForward(o);
        o.executed = true;
        emit FilledSL(id, price, msg.sender);
    }

    /* ─────────────────── Cancel ─────────────────── */

    function cancel(uint256 id) external {
        Order storage o = orders[id];
        require(msg.sender == o.trader, "not trader");
        _active(o);
        o.cancelled = true;
        emit Cancelled(id);
    }

    /* ─────────────────── Internals ─────────────────── */

    function _active(Order storage o) private view {
        require(!o.executed && !o.cancelled, "inactive");
    }

    function _pullAndForward(Order storage o) private {
        // Pull asset from trader via permit
        o.asset.permit(o.trader, address(this), o.amount, o.deadline, o.v, o.r, o.s);
        // Forward to router
        IERC20(address(o.asset)).safeTransferFrom(o.trader, o.router, o.amount);
        // (Optional) add swap logic or emit further events here
    }
}
