// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * ──────────────────────────────────────────────────────────────────────────
 *  One‑Cancels‑the‑Other (OCO) Order Vault – v0.3
 * ──────────────────────────────────────────────────────────────────────────
 *  • Trader deposits `assetToken` and sets a take‑profit and stop‑loss price.
 *  • First trigger executed cancels the alternate side automatically.
 *  • Executor bot earns an optional `gasReward` bounty.
 *
 *  FIX: Replaced the Unicode ≤ in the require string with ASCII "<=",
 *       removing the Solidity parser error.
 */
contract OCOOrderBook is Ownable {
    using SafeERC20 for IERC20;

    struct Order {
        address trader;
        IERC20  assetToken;
        IERC20  quoteToken;
        uint256 amount;
        uint256 takeProfitPrice; // quote/asset (1e18)
        uint256 stopLossPrice;   // quote/asset (1e18)
        address exchangeRouter;
        uint256 gasReward;
        bool    executed;
        bool    cancelled;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Order) public orders;

    event OCOPlaced(uint256 indexed id, address indexed trader);
    event OCOTakeProfit(uint256 indexed id, uint256 price, address executor);
    event OCOStopLoss (uint256 indexed id, uint256 price, address executor);
    event OCOCancelled(uint256 indexed id);

    constructor() Ownable(msg.sender) {}

    /* ─────────────────────────────────────────────── */
    /*                  Place order                    */
    /* ─────────────────────────────────────────────── */
    function placeOCO(
        IERC20  assetToken,
        IERC20  quoteToken,
        uint256 amount,
        uint256 tpPrice,
        uint256 slPrice,
        address exchangeRouter,
        uint256 gasReward
    ) external returns (uint256 id) {
        require(amount > 0, "zero amount");
        require(tpPrice > slPrice, "tp <= sl"); // ← ASCII characters only
        require(exchangeRouter != address(0), "router 0");

        id = nextId++;
        orders[id] = Order({
            trader: msg.sender,
            assetToken: assetToken,
            quoteToken: quoteToken,
            amount: amount,
            takeProfitPrice: tpPrice,
            stopLossPrice: slPrice,
            exchangeRouter: exchangeRouter,
            gasReward: gasReward,
            executed: false,
            cancelled: false
        });

        assetToken.safeTransferFrom(msg.sender, address(this), amount);
        emit OCOPlaced(id, msg.sender);
    }

    /* ─────────────────────────────────────────────── */
    /*                 Execute orders                  */
    /* ─────────────────────────────────────────────── */
    function executeTakeProfit(uint256 id, uint256 marketPrice) external {
        Order storage o = orders[id];
        _requireActive(o);
        require(marketPrice >= o.takeProfitPrice, "price < TP");

        o.executed = true;
        _settle(o, msg.sender);
        emit OCOTakeProfit(id, marketPrice, msg.sender);
    }

    function executeStopLoss(uint256 id, uint256 marketPrice) external {
        Order storage o = orders[id];
        _requireActive(o);
        require(marketPrice <= o.stopLossPrice, "price > SL");

        o.executed = true;
        _settle(o, msg.sender);
        emit OCOStopLoss(id, marketPrice, msg.sender);
    }

    /* ─────────────────────────────────────────────── */
    /*                   Cancellation                  */
    /* ─────────────────────────────────────────────── */
    function cancel(uint256 id) external {
        Order storage o = orders[id];
        require(msg.sender == o.trader, "not trader");
        _requireActive(o);

        o.cancelled = true;
        o.assetToken.safeTransfer(o.trader, o.amount);
        emit OCOCancelled(id);
    }

    /* ─────────────────────────────────────────────── */
    /*                    Internals                    */
    /* ─────────────────────────────────────────────── */
    function _requireActive(Order storage o) private view {
        require(!o.executed && !o.cancelled, "inactive");
    }

    function _settle(Order storage o, address executor) private {
        o.assetToken.safeTransfer(o.exchangeRouter, o.amount);
        if (o.gasReward > 0) {
            o.quoteToken.safeTransferFrom(o.trader, executor, o.gasReward);
        }
    }

    /* Admin rescue */
    function rescue(IERC20 token, address to, uint256 amount)
        external onlyOwner
    { token.safeTransfer(to, amount); }
}
