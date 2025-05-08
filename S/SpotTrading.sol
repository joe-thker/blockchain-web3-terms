// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
}

abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

/// ---------------------------------------------
/// 1) AMM Spot Swap
/// ---------------------------------------------
contract SpotSwap is Base, ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint112 public reserveA;
    uint112 public reserveB;

    constructor(address _a, address _b) {
        tokenA = IERC20(_a);
        tokenB = IERC20(_b);
    }

    // --- Attack: no slippage check, vulnerable to reentrancy
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

/// ---------------------------------------------
/// 2) Spot Limit Order Book
/// ---------------------------------------------
contract SpotLimitBook is Base {
    struct Order {
        address user;
        bool    isBuy;
        uint256 amountIn;
        uint256 limitPrice; // scaled 1e18
        bool    filled;
    }
    mapping(uint256 => Order) public orders;
    uint256 public nextOrder;

    // --- Attack: no price enforcement or replay protection
    function postOrderInsecure(
        bool isBuy, uint256 amtIn, uint256 limitPrice
    ) external {
        orders[nextOrder++] = Order(msg.sender, isBuy, amtIn, limitPrice, false);
    }
    function fillOrderInsecure(uint256 id, uint256 executionPrice) external {
        Order storage o = orders[id];
        require(!o.filled, "Filled");
        o.filled = true;
        // transfer logic omitted
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

/// ---------------------------------------------
/// 3) Spot Stop-Loss Orders
/// ---------------------------------------------
interface IOracle {
    function latestAnswer() external view returns (uint256 price, uint256 updatedAt);
}

contract SpotStopLoss is Base, ReentrancyGuard {
    IERC20 public token;
    IOracle[] public oracles;
    uint256 public staleAfter;    // seconds

    struct SLOrder {
        address user;
        uint256 amount;
        uint256 stopPrice;  // scaled 1e18
        bool    executed;
    }
    mapping(uint256 => SLOrder) public slOrders;
    uint256 public nextSL;

    constructor(address _token, IOracle[] memory _oracles, uint256 _staleSec) {
        token      = IERC20(_token);
        oracles    = _oracles;
        staleAfter = _staleSec;
    }

    function postSLInsecure(uint256 amount, uint256 stopPrice) external {
        slOrders[nextSL++] = SLOrder(msg.sender, amount, stopPrice, false);
    }

    // --- Attack: triggers on stale or single‐oracle price, allows replay
    function triggerSLInsecure(uint256 id) external {
        SLOrder storage o = slOrders[id];
        require(!o.executed, "Done");
        (uint256 p,) = oracles[0].latestAnswer();
        require(p <= o.stopPrice, "Not triggered");
        o.executed = true;
        token.transfer(o.user, o.amount);
    }

    // --- Defense: multi‐oracle TWAP + freshness + replay guard
    function triggerSLSecure(uint256 id) external nonReentrant {
        SLOrder storage o = slOrders[id];
        require(!o.executed, "Already executed");
        uint256 sum;
        for (uint i; i < oracles.length; i++) {
            (uint256 p, uint256 when) = oracles[i].latestAnswer();
            require(block.timestamp - when <= staleAfter, "Oracle stale");
            sum += p;
        }
        uint256 avg = sum / oracles.length;
        require(avg <= o.stopPrice, "Not triggered");
        o.executed = true;
        token.transfer(o.user, o.amount);
    }
}
