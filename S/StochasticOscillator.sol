// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPriceFeed {
    // returns price with 1e8 precision and timestamp
    function getLatest() external view returns (uint256 price, uint256 updatedAt);
}

/// @title StochasticOscillatorSuite
/// @notice 1) OscillatorCalc, 2) SignalGen, 3) AutoTrader
contract StochasticOscillatorSuite is ReentrancyGuard {
    IPriceFeed[] public feeds;      // multiple oracles
    uint256 public staleAfter = 300; // seconds
    uint256 public epsilon    = 1;   // to avoid div0

    constructor(IPriceFeed[] memory _feeds) {
        feeds = _feeds;
    }

    /// ------------------------------------------------------------------------
    /// 1) On‐Chain %K Calculation
    /// ------------------------------------------------------------------------
    // insecure: use single stale feed + no div0 guard
    function percentKInsecure(uint256 lowest, uint256 highest) external view returns (uint256) {
        // grab only first feed
        (uint256 close, ) = feeds[0].getLatest();
        // no freshness or range checks
        return (close - lowest) * 100 / (highest - lowest);
    }

    // secure: aggregate TWAP, freshness & div‐zero guard
    function percentKSecure(uint256 lowest, uint256 highest) external view returns (uint256) {
        require(highest > lowest, "Invalid range");
        // aggregate TWAP
        uint256 sum; uint256 n = feeds.length;
        for (uint i = 0; i < n; i++) {
            (uint256 p, uint256 when) = feeds[i].getLatest();
            require(block.timestamp - when <= staleAfter, "Oracle stale");
            sum += p;
        }
        uint256 close = sum / n;
        uint256 denom = (highest - lowest) + epsilon;
        // clamp numerator ≥0
        uint256 num = close >= lowest ? close - lowest : 0;
        uint256 k = num * 100 * 1e8 / denom; // scaled by 1e8
        return k > 100*1e8 ? 100*1e8 : k;
    }

    /// ------------------------------------------------------------------------
    /// 2) Signal Generation (Threshold)
    /// ------------------------------------------------------------------------
    mapping(bytes32=>uint256) public lastSignalTime;
    uint256 public signalCooldown = 60; // seconds

    // insecure: immediate threshold check, no debounce
    function isOverboughtInsecure(uint256 k, uint256 threshold) external pure returns(bool) {
        return k >= threshold;
    }

    // secure: clamp, debounce by cooldown, require valid threshold
    function isOverboughtSecure(uint256 k, uint256 threshold) external returns(bool) {
        require(threshold <= 100*1e8, "Bad thresh");
        // clamp k to [0,100]
        uint256 kk = k > 100*1e8 ? 100*1e8 : k;
        bool sig = kk >= threshold;
        // debounce per caller + function signature
        bytes32 key = keccak256(abi.encodePacked(msg.sender, "OB"));
        if (sig && block.timestamp >= lastSignalTime[key] + signalCooldown) {
            lastSignalTime[key] = block.timestamp;
            return true;
        }
        return false;
    }

    /// ------------------------------------------------------------------------
    /// 3) Automated Trade Execution
    /// ------------------------------------------------------------------------
    IERC20 public tokenIn;
    IERC20 public tokenOut;
    uint112 public reserveIn;
    uint112 public reserveOut;

    // insecure: no slippage, no deadline, vulnerable to reentrancy
    function tradeInsecure(uint256 amountIn) external {
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        uint256 out = reserveOut * amountIn / reserveIn;
        reserveIn  += uint112(amountIn);
        reserveOut -= uint112(out);
        tokenOut.transfer(msg.sender, out);
    }

    // secure: TWAP‐based price check, minOut, deadline, CEI & reentrancy guard
    function tradeSecure(
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline,
        uint256 twapPrice,
        uint256 twapUpdated
    ) external nonReentrant {
        require(block.timestamp <= deadline, "Deadline");
        // verify TWAP freshness
        require(block.timestamp - twapUpdated <= staleAfter, "TWAP stale");
        // check price bounds: out ≥ amountIn * price
        uint256 expectedOut = amountIn * twapPrice / 1e8;
        require(expectedOut >= minAmountOut, "Slippage/profit violation");

        // CEI
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        reserveIn  += uint112(amountIn);

        // actual AMM formula with fee
        uint256 inWithFee = amountIn * 997 / 1000;
        uint256 num = inWithFee * reserveOut;
        uint256 den = reserveIn * 1000 + inWithFee;
        uint256 out = num / den;

        require(out >= minAmountOut, "Slippage too high");
        reserveOut -= uint112(out);
        tokenOut.transfer(msg.sender, out);
    }
}
