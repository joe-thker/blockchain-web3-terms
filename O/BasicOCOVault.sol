// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Basic OCO Vault
 * • Trader deposits `assetToken`.
 * • Executor triggers take‑profit (price ≥ TP) or stop‑loss (price ≤ SL).
 * • First fill cancels the other side; executor can earn `gasReward`.
 */
contract BasicOCOVault is Ownable {
    using SafeERC20 for IERC20;

    struct Order {
        address trader;
        IERC20  assetToken;
        IERC20  quoteToken;
        uint256 amount;
        uint256 tp;              // take‑profit price (1e18, quote / asset)
        uint256 sl;              // stop‑loss  price (1e18, quote / asset)
        address router;          // DEX router that receives asset
        uint256 gasReward;       // bounty in quote token
        bool executed;
        bool cancelled;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Order) public orders;

    event Placed(uint256 indexed id, address indexed trader);
    event FilledTP(uint256 indexed id, uint256 price, address executor);
    event FilledSL(uint256 indexed id, uint256 price, address executor);
    event Cancelled(uint256 indexed id);

    constructor() Ownable(msg.sender) {}

    /* ─────────── Place order ─────────── */
    function place(
        IERC20 asset,
        IERC20 quote,
        uint256 amount,
        uint256 tpPrice,
        uint256 slPrice,
        address router,
        uint256 gasReward
    ) external returns (uint256 id) {
        require(amount > 0,        "zero amount");
        require(tpPrice > slPrice, "tp <= sl");
        require(router != address(0), "router 0");

        id = nextId++;
        orders[id] = Order({
            trader: msg.sender,
            assetToken: asset,
            quoteToken: quote,
            amount: amount,
            tp: tpPrice,
            sl: slPrice,
            router: router,
            gasReward: gasReward,
            executed: false,
            cancelled: false
        });

        asset.safeTransferFrom(msg.sender, address(this), amount);
        emit Placed(id, msg.sender);
    }

    /* ─────────── Execution ─────────── */
    function executeTP(uint256 id, uint256 marketPrice) external {
        Order storage o = orders[id];
        _requireActive(o);
        require(marketPrice >= o.tp, "price < TP");
        o.executed = true;
        _settle(o, msg.sender);
        emit FilledTP(id, marketPrice, msg.sender);
    }

    function executeSL(uint256 id, uint256 marketPrice) external {
        Order storage o = orders[id];
        _requireActive(o);
        require(marketPrice <= o.sl, "price > SL");
        o.executed = true;
        _settle(o, msg.sender);
        emit FilledSL(id, marketPrice, msg.sender);
    }

    /* ─────────── Cancel ─────────── */
    function cancel(uint256 id) external {
        Order storage o = orders[id];
        require(msg.sender == o.trader, "not trader");
        _requireActive(o);
        o.cancelled = true;
        o.assetToken.safeTransfer(o.trader, o.amount);
        emit Cancelled(id);
    }

    /* ─────────── Internals ─────────── */
    function _requireActive(Order storage o) private view {
        require(!o.executed && !o.cancelled, "inactive");
    }

    function _settle(Order storage o, address executor) private {
        o.assetToken.safeTransfer(o.router, o.amount);
        if (o.gasReward > 0) {
            o.quoteToken.safeTransferFrom(o.trader, executor, o.gasReward);
        }
    }
}
