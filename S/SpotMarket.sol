// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    constructor() { owner = msg.sender; }
}

/// Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _lock;
    modifier nonReentrant() {
        require(!_lock, "Reentrant");
        _lock = true;
        _;
        _lock = false;
    }
}

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

////////////////////////////////////////////
// 1) Spot Trade Execution (AMM‐Style)
////////////////////////////////////////////
contract SpotTrade is Base, ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint112 public reserveA;
    uint112 public reserveB;

    constructor(address _a, address _b) {
        tokenA = IERC20(_a);
        tokenB = IERC20(_b);
    }

    // --- Attack: no slippage check, vulnerable to reentrancy
    function tradeInsecure(uint256 amountAIn) external {
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        uint256 outB = uint256(reserveB) * amountAIn / reserveA;
        reserveA += uint112(amountAIn);
        reserveB -= uint112(outB);
        tokenB.transfer(msg.sender, outB);
    }

    // --- Defense: require minAmountOut + CEI + nonReentrant
    function tradeSecure(uint256 amountAIn, uint256 minBOut) external nonReentrant {
        require(amountAIn > 0, "Zero in");
        tokenA.transferFrom(msg.sender, address(this), amountAIn);

        // simple 0.3% fee model
        uint256 amountInWithFee = amountAIn * 997 / 1000;
        uint256 numerator   = amountInWithFee * reserveB;
        uint256 denominator = reserveA * 1000 + amountInWithFee;
        uint256 outB        = numerator / denominator;

        require(outB >= minBOut, "Slippage too high");

        reserveA += uint112(amountAIn);
        reserveB -= uint112(outB);
        tokenB.transfer(msg.sender, outB);
    }
}

////////////////////////////////////////////
// 2) Spot Order Book (Limit Orders)
////////////////////////////////////////////
contract SpotOrderBook is Base {
    struct Order {
        address user;
        bool    isBuy;
        uint256 amountIn;
        uint256 limitPrice; // scaled 1e18
        bool    filled;
    }
    mapping(uint256 => Order) public orders;
    uint256 public nextOrder;

    // --- Attack: no limit enforcement or replay protection
    function postOrderInsecure(
        bool isBuy, uint256 amtIn, uint256 limitPrice
    ) external {
        orders[nextOrder++] = Order(msg.sender, isBuy, amtIn, limitPrice, false);
    }
    function fillOrderInsecure(uint256 id, uint256 executionPrice) external {
        Order storage o = orders[id];
        require(!o.filled, "Filled");
        o.filled = true;
        // no price check; transfers omitted
    }

    // --- Defense: enforce price bound + prevent replay
    function postOrderSecure(
        bool isBuy, uint256 amtIn, uint256 limitPrice
    ) external {
        require(amtIn > 0, "Zero amt");
        require(limitPrice > 0, "Zero price");
        orders[nextOrder++] = Order(msg.sender, isBuy, amtIn, limitPrice, false);
    }
    function fillOrderSecure(uint256 id, uint256 executionPrice) external {
        Order storage o = orders[id];
        require(!o.filled, "Already filled");
        if (o.isBuy) {
            require(executionPrice <= o.limitPrice, "Exec above limit");
        } else {
            require(executionPrice >= o.limitPrice, "Exec below limit");
        }
        o.filled = true;
        // perform transfers here...
    }
}

////////////////////////////////////////////
// 3) Spot Market Data Feed
////////////////////////////////////////////
interface IOracle {
    function latestAnswer() external view returns (uint256 price, uint256 updatedAt);
}

contract SpotDataFeed is Base {
    IOracle[] public oracles;
    uint256 public staleAfter;    // seconds

    constructor(IOracle[] memory _oracles, uint256 _staleSec) {
        oracles    = _oracles;
        staleAfter = _staleSec;
    }

    // --- Attack: single oracle, no freshness ⇒ manipulations or stale
    function priceInsecure() external view returns (uint256) {
        (uint256 p, ) = oracles[0].latestAnswer();
        return p;
    }

    // --- Defense: aggregate TWAP + freshness + sanity
    function priceSecure() external view returns (uint256) {
        uint256 sum;
        uint256 n = oracles.length;
        require(n > 0, "No oracles");
        for (uint i; i < n; i++) {
            (uint256 p, uint256 when) = oracles[i].latestAnswer();
            require(block.timestamp - when <= staleAfter, "Oracle stale");
            sum += p;
        }
        uint256 avg = sum / n;
        require(avg > 0, "Invalid price");
        return avg;
    }
}
