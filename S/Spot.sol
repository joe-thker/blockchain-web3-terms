// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    constructor() { owner = msg.sender; }
}

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
    function transferFrom(address from, address to, uint256 amt) external returns (bool);
    function transfer(address to, uint256 amt) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

//////////////////////////////////////////
// 1) Spot Swap Execution (AMM)
//////////////////////////////////////////
contract SpotSwap is Base, ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint112 public reserveA;
    uint112 public reserveB;

    constructor(address _a, address _b) {
        tokenA = IERC20(_a);
        tokenB = IERC20(_b);
    }

    // --- Attack: no slippage check, no reentrancy guard
    function swapInsecure(uint256 amountAIn) external {
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        uint256 outB = uint256(reserveB) * amountAIn / reserveA;
        reserveA += uint112(amountAIn);
        reserveB -= uint112(outB);
        tokenB.transfer(msg.sender, outB);
    }

    // --- Defense: require minAmountOut + CEI + nonReentrant
    function swapSecure(uint256 amountAIn, uint256 minBOut) external nonReentrant {
        require(amountAIn > 0, "Zero in");
        tokenA.transferFrom(msg.sender, address(this), amountAIn);

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

//////////////////////////////////////////
// 2) Spot Limit Order
//////////////////////////////////////////
contract SpotLimitOrder is Base {
    struct Order {
        address user;
        bool    isBuy;
        uint256 amountIn;
        uint256 limitPrice; // price expressed as tokenB per tokenA scaled 1e18
        bool    filled;
    }
    mapping(uint256 => Order) public orders;
    uint256 public nextOrder;

    // --- Attack: no limit enforcement or replay protection
    function createOrderInsecure(
        bool isBuy, uint256 amtIn, uint256 limitPrice
    ) external {
        orders[nextOrder++] = Order(msg.sender, isBuy, amtIn, limitPrice, false);
    }
    function fillOrderInsecure(uint256 id, uint256 executionPrice) external {
        Order storage o = orders[id];
        require(!o.filled, "Already filled");
        // no price check; just mark filled
        o.filled = true;
        // transfer logic omitted
    }

    // --- Defense: enforce price bound + prevent replay
    function createOrderSecure(
        bool isBuy, uint256 amtIn, uint256 limitPrice
    ) external {
        require(amtIn > 0, "Zero amount");
        require(limitPrice > 0, "Zero price");
        orders[nextOrder++] = Order(msg.sender, isBuy, amtIn, limitPrice, false);
    }
    function fillOrderSecure(
        uint256 id, uint256 executionPrice
    ) external {
        Order storage o = orders[id];
        require(!o.filled, "Already filled");
        if (o.isBuy) {
            // user wants to buy tokenA with tokenB; executionPrice must be ≤ limit
            require(executionPrice <= o.limitPrice, "Price above limit");
        } else {
            // sell: executionPrice must be ≥ limit
            require(executionPrice >= o.limitPrice, "Price below limit");
        }
        o.filled = true;
        // execute transfers here...
    }
}

//////////////////////////////////////////
// 3) Spot Price Oracle Consumption
//////////////////////////////////////////
interface IOracle {
    function latestAnswer() external view returns (uint256 price, uint256 updatedAt);
}

contract SpotPriceFeed is Base {
    IOracle[] public oracles;
    uint256 public staleAfter;    // seconds

    constructor(IOracle[] memory _oracles, uint256 _staleSec) {
        oracles     = _oracles;
        staleAfter  = _staleSec;
    }

    // --- Attack: single oracle, no freshness → manipulable or stale
    function getPriceInsecure() external view returns (uint256) {
        (uint256 p, ) = oracles[0].latestAnswer();
        return p;
    }

    // --- Defense: aggregate TWAP + sanity + freshness
    function getPriceSecure() external view returns (uint256) {
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
