// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IOracle {
    /// @return price with 1e18 precision, timestamp of last update
    function latest() external view returns (uint256 price, uint256 updatedAt);
}

interface IERC20 {
    function transfer(address to, uint256 amt) external returns (bool);
    function transferFrom(address from, address to, uint256 amt) external returns (bool);
}

/// @title StopLossSuite
/// @notice 1) BasicStopLoss, 2) TrailingStopLoss, 3) StopLimitOrder
contract StopLossSuite is ReentrancyGuard {
    IOracle[] public oracles;
    uint256 public staleAfter = 300;    // max age of oracle data
    uint256 public epsilon    = 1;      // to avoid div-by-zero

    constructor(IOracle[] memory _oracles) {
        oracles = _oracles;
    }

    /// ------------------------------------------------------------------------
    /// 1) Basic Stop-Loss Trigger
    /// ------------------------------------------------------------------------
    struct SL {
        address user;
        IERC20  tokenIn;
        IERC20  tokenOut;
        uint256 amountIn;
        uint256 stopPrice;   // price threshold scaled 1e18
        bool    executed;
    }
    mapping(uint256=>SL) public sls;
    uint256 public slCount;

    // --- Attack: single-oracle, no stale check, no replay guard
    function createBasicSLInsecure(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        uint256 stopPrice
    ) external {
        sls[slCount++] = SL(msg.sender, tokenIn, tokenOut, amountIn, stopPrice, false);
    }
    function triggerBasicSLInsecure(uint256 id) external {
        SL storage o = sls[id];
        require(!o.executed, "Done");
        (uint256 p, ) = oracles[0].latest();
        require(p <= o.stopPrice, "Not triggered");
        o.executed = true;
        o.tokenIn.transferFrom(o.user, address(this), o.amountIn);
        // naive price-based swap
        o.tokenOut.transfer(o.user, o.amountIn * p / 1e18);
    }

    // --- Defense: multi-oracle TWAP, stale check, replay guard, nonReentrant
    function triggerBasicSLSecure(uint256 id) external nonReentrant {
        SL storage o = sls[id];
        require(!o.executed, "Already executed");
        // TWAP aggregate
        uint256 sum; uint256 n = oracles.length;
        for (uint i = 0; i < n; i++) {
            (uint256 p, uint256 t) = oracles[i].latest();
            require(block.timestamp - t <= staleAfter, "Oracle stale");
            sum += p;
        }
        uint256 price = sum / n;
        require(price <= o.stopPrice, "Not triggered");
        o.executed = true;
        // CEI
        o.tokenIn.transferFrom(o.user, address(this), o.amountIn);
        uint256 out = o.amountIn * price / 1e18;
        o.tokenOut.transfer(o.user, out);
    }

    /// ------------------------------------------------------------------------
    /// 2) Trailing Stop-Loss
    /// ------------------------------------------------------------------------
    struct TSL {
        address user;
        IERC20  tokenIn;
        IERC20  tokenOut;
        uint256 amountIn;
        uint256 trailingStep;   // e.g. 5% = 500 BP
        uint256 highestPrice;   // updated on each check
        bool    executed;
    }
    mapping(uint256=>TSL) public tsls;
    uint256 public tslCount;

    // --- Attack: never updates highestPrice, stale single oracle
    function createTSLInsecure(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        uint256 trailingStep
    ) external {
        tsls[tslCount++] = TSL(msg.sender, tokenIn, tokenOut, amountIn, trailingStep, 0, false);
    }
    function checkTSLInsecure(uint256 id) external {
        TSL storage o = tsls[id];
        require(!o.executed, "Done");
        (uint256 p, ) = oracles[0].latest();
        // no update of highestPrice ⇒ highestPrice remains zero
        require(p <= o.highestPrice * (10000 - o.trailingStep) / 10000, "Not triggered");
        o.executed = true;
        // execution omitted
    }

    // --- Defense: update highestPrice each call, enforce minStep, TWAP & stale, nonReentrant
    function checkTSLSecure(uint256 id) external nonReentrant {
        TSL storage o = tsls[id];
        require(!o.executed, "Already executed");
        // compute TWAP
        uint256 sum; uint256 n = oracles.length;
        for (uint i = 0; i < n; i++) {
            (uint256 p, uint256 t) = oracles[i].latest();
            require(block.timestamp - t <= staleAfter, "Oracle stale");
            sum += p;
        }
        uint256 price = sum / n;
        // initialize highestPrice on first check
        if (o.highestPrice == 0) {
            o.highestPrice = price;
            return;
        }
        // update highestPrice if price rose enough above minStep
        uint256 minStepVal = o.highestPrice * epsilon / 1e18; // ensure >0
        if (price > o.highestPrice + minStepVal) {
            o.highestPrice = price;
            return;
        }
        // trigger when price falls trailingStep below highestPrice
        uint256 triggerPrice = o.highestPrice * (10000 - o.trailingStep) / 10000;
        require(price <= triggerPrice, "Not triggered");
        o.executed = true;
        // CEI & execution omitted for brevity
    }

    /// ------------------------------------------------------------------------
    /// 3) Stop-Limit Order
    /// ------------------------------------------------------------------------
    struct SLO {
        address user;
        IERC20  tokenIn;
        IERC20  tokenOut;
        uint256 amountIn;
        uint256 stopPrice;   // when to start
        uint256 limitPrice;  // worst acceptable execution
        uint256 deadline;    // unix timestamp
        bool    executed;
    }
    mapping(uint256=>SLO) public slos;
    uint256 public sloCount;

    // --- Attack: ignores limitPrice & deadline, no slippage guard
    function createSLOInsecure(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        uint256 stopPrice,
        uint256 limitPrice
    ) external {
        slos[sloCount++] = SLO(msg.sender, tokenIn, tokenOut, amountIn, stopPrice, limitPrice, 0, false);
    }
    function triggerSLOInsecure(uint256 id) external {
        SLO storage o = slos[id];
        require(!o.executed, "Done");
        (uint256 p, ) = oracles[0].latest();
        // no stop check, no limit check
        require(p <= o.stopPrice, "Not in stop range");
        o.executed = true;
        // naive swap at market price p
        o.tokenIn.transferFrom(o.user, address(this), o.amountIn);
        o.tokenOut.transfer(o.user, o.amountIn * p / 1e18);
    }

    // --- Defense: enforce stop → limit → deadline → CEI → nonReentrant
    function triggerSLOSecure(
        uint256 id,
        uint256 deadline,
        uint256 minAmountOut
    ) external nonReentrant {
        SLO storage o = slos[id];
        require(!o.executed, "Already executed");
        // store deadline on first trigger
        if (o.deadline == 0) {
            o.deadline = deadline;
        }
        require(block.timestamp <= o.deadline, "Deadline passed");
        // TWAP aggregate
        uint256 sum; uint256 n = oracles.length;
        for (uint i = 0; i < n; i++) {
            (uint256 p, uint256 t) = oracles[i].latest();
            require(block.timestamp - t <= staleAfter, "Oracle stale");
            sum += p;
        }
        uint256 price = sum / n;
        // stop-price check
        require(price <= o.stopPrice, "Stop not hit");
        // limit-price check
        require(price >= o.limitPrice, "Price below limit");
        o.executed = true;
        // CEI: transfer in
        o.tokenIn.transferFrom(o.user, address(this), o.amountIn);
        // slippage/deadline safe swap
        uint256 out = o.amountIn * price / 1e18;
        require(out >= minAmountOut, "Slippage too high");
        o.tokenOut.transfer(o.user, out);
    }
}
