// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
interface IOracle { function latest() external view returns (uint256 price, uint256 updatedAt); }
interface IERC20 {
    function transferFrom(address, address, uint256) external returns(bool);
    function transfer(address, uint256) external returns(bool);
}

/// @title SupportLevelSuite
/// @notice 1) SupportDetector, 2) SupportLimitOrder, 3) SupportAutoBuy
contract SupportLevelSuite is ReentrancyGuard {
    // common
    IOracle[] public oracles;
    uint256 public staleAfter = 300; // seconds
    uint256 public epsilon    = 1;   // avoid div0

    constructor(IOracle[] memory _oracles) {
        oracles = _oracles;
    }

    /// ------------------------------------------------------------------------
    /// 1) On-Chain Support Detection
    /// ------------------------------------------------------------------------
    // --- Attack: single oracle, no stale check
    function isSupportInsecure(uint256 level) external view returns (bool) {
        (uint256 p, ) = oracles[0].latest();
        return p <= level;
    }

    // --- Defense: TWAP average + freshness
    function isSupportSecure(uint256 level) public view returns (bool) {
        uint256 sum; uint256 n = oracles.length;
        require(n > 0, "No oracles");
        for (uint i; i < n; i++) {
            (uint256 p, uint256 t) = oracles[i].latest();
            require(block.timestamp - t <= staleAfter, "Oracle stale");
            sum += p;
        }
        uint256 avg = sum / n;
        return avg <= level;
    }

    /// ------------------------------------------------------------------------
    /// 2) Support-Based Limit Buy Order
    /// ------------------------------------------------------------------------
    struct SLOrder {
        address user;
        IERC20  tokenIn;
        IERC20  tokenOut;
        uint256 amountIn;
        uint256 supportLevel;
        bool    filled;
    }
    mapping(uint256 => SLOrder) public orders;
    uint256 public nextOrder;

    // --- Attack: no price check or replay guard
    function createOrderInsecure(
        IERC20 inT,
        IERC20 outT,
        uint256 amtIn,
        uint256 supportLevel
    ) external {
        orders[nextOrder++] = SLOrder(msg.sender, inT, outT, amtIn, supportLevel, false);
    }
    function triggerOrderInsecure(uint256 id) external {
        SLOrder storage o = orders[id];
        require(!o.filled, "Filled");
        (uint256 p, ) = oracles[0].latest();
        require(p <= o.supportLevel, "Price above support");
        o.filled = true;
        o.tokenIn.transferFrom(o.user, address(this), o.amountIn);
        o.tokenOut.transfer(o.user, o.amountIn * o.supportLevel / 1e18);
    }

    // --- Defense: enforce aggregated support + replay guard
    function triggerOrderSecure(uint256 id) external {
        SLOrder storage o = orders[id];
        require(!o.filled, "Already filled");
        require(isSupportSecure(o.supportLevel), "No support hit");
        o.filled = true;
        // CEI
        o.tokenIn.transferFrom(o.user, address(this), o.amountIn);
        uint256 outAmt = o.amountIn * o.supportLevel / 1e18;
        o.tokenOut.transfer(o.user, outAmt);
    }

    /// ------------------------------------------------------------------------
    /// 3) Automated Bounce Execution
    /// ------------------------------------------------------------------------
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint112 public reserveA;
    uint112 public reserveB;

    // set tokens & reserves
    function initAMM(address a, address b, uint112 a0, uint112 b0) external {
        tokenA = IERC20(a);
        tokenB = IERC20(b);
        reserveA = a0;
        reserveB = b0;
    }

    // --- Attack: no slippage/deadline/reentrancy guard
    function buyInsecure(uint256 amountAIn) external {
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        uint256 outB = reserveB * amountAIn / reserveA;
        reserveA += amountAIn;
        reserveB -= uint112(outB);
        tokenB.transfer(msg.sender, outB);
    }

    // --- Defense: support bounce + TWAP + CEI + nonReentrant + slippage/deadline
    function buySecure(
        uint256 amountAIn,
        uint256 minBOut,
        uint256 deadline,
        uint256 supportLevel,
        uint256 twapPrice,
        uint256 twapUpdated
    ) external nonReentrant {
        require(block.timestamp <= deadline, "Deadline");
        // ensure bounce: price now above support
        require(isSupportSecure(supportLevel), "Support not hit");
        // verify provided TWAP for slippage calc
        require(block.timestamp - twapUpdated <= staleAfter, "TWAP stale");
        uint256 expectedOut = amountAIn * twapPrice / 1e18;
        require(expectedOut >= minBOut, "Slippage guard");

        // CEI
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        uint256 a0 = reserveA;
        uint256 b0 = reserveB;

        // AMM formula with 0.3% fee
        uint256 inWithFee = amountAIn * 997 / 1000;
        uint256 num = inWithFee * b0;
        uint256 den = a0 * 1000 + inWithFee;
        uint256 outB = num / den;
        require(outB >= minBOut, "Slippage too high");

        reserveA = uint112(a0 + amountAIn);
        reserveB = uint112(b0 - outB);
        tokenB.transfer(msg.sender, outB);
    }
}
