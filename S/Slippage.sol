// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
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

/// Minimal ERC20 interface
interface IERC20 {
    function transfer(address to, uint256 amt) external returns (bool);
    function transferFrom(address fr, address to, uint256 amt) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

/// 1) Spot Swap Execution
contract SwapModule is Base, ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint112  public reserveA;
    uint112  public reserveB;

    constructor(address _a, address _b) {
        tokenA = IERC20(_a);
        tokenB = IERC20(_b);
    }

    // --- Attack: no slippage check, no CEI
    function swapInsecure(uint256 amountAIn) external {
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        // simplistic constant-product price
        uint256 amountBOut = reserveB * amountAIn / reserveA;
        reserveA += uint112(amountAIn);
        reserveB -= uint112(amountBOut);
        tokenB.transfer(msg.sender, amountBOut);
    }

    // --- Defense: require minAmountOut + CEI + reentrancy guard
    function swapSecure(uint256 amountAIn, uint256 minBOut) external nonReentrant {
        require(amountAIn > 0, "Zero in");
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        // compute amount out with fee (e.g. 0.3%)
        uint256 amountInWithFee = amountAIn * 997 / 1000;
        uint256 numerator   = amountInWithFee * reserveB;
        uint256 denominator = reserveA * 1000 + amountInWithFee;
        uint256 amountBOut  = numerator / denominator;
        require(amountBOut >= minBOut, "Slippage too high");
        // Effects
        reserveA += uint112(amountAIn);
        reserveB -= uint112(amountBOut);
        // Interaction
        tokenB.transfer(msg.sender, amountBOut);
    }
}

/// 2) Limit-Price Order
contract LimitOrderModule is Base {
    struct Order { address user; uint256 amount; uint256 price; bool isBuy; bool filled; }
    mapping(uint256 => Order) public orders;
    uint256 public nextOrder;

    // --- Attack: no price enforcement, replay allowed
    function createOrderInsecure(uint256 amount, uint256 price, bool isBuy) external {
        orders[nextOrder++] = Order(msg.sender, amount, price, isBuy, false);
    }
    function fillOrderInsecure(uint256 id) external {
        Order storage o = orders[id];
        require(!o.filled, "Filled");
        o.filled = true;
        // no price check; should transfer tokens/ETH
    }

    // --- Defense: enforce price limit + prevent replay
    function createOrderSecure(uint256 amount, uint256 price, bool isBuy) external {
        require(amount > 0, "Zero amount");
        require(price > 0,  "Zero price");
        orders[nextOrder++] = Order(msg.sender, amount, price, isBuy, false);
    }
    function fillOrderSecure(uint256 id, uint256 executionPrice) external nonReentrant {
        Order storage o = orders[id];
        require(!o.filled, "Already filled");
        // For buy orders, executionPrice must be <= price (user max)
        // For sell orders, executionPrice must be >= price (user min)
        if (o.isBuy) {
            require(executionPrice <= o.price, "Price too high");
        } else {
            require(executionPrice >= o.price, "Price too low");
        }
        o.filled = true;
        // transfer logic here
    }
}

/// 3) Liquidity Withdrawal
contract LiquidityModule is Base, ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public totalSupply;    // LP tokens
    mapping(address => uint256) public balanceOf;

    constructor(address _a, address _b) {
        tokenA = IERC20(_a);
        tokenB = IERC20(_b);
    }

    // --- Attack: withdraw any proportions, no min checks
    function removeLiquidityInsecure(uint256 lpAmount) external {
        require(balanceOf[msg.sender] >= lpAmount, "Insufficient LP");
        balanceOf[msg.sender] -= lpAmount;
        totalSupply         -= lpAmount;
        // naive: return proportional reserves
        uint256 amtA = tokenA.balanceOf(address(this)) * lpAmount / totalSupply;
        uint256 amtB = tokenB.balanceOf(address(this)) * lpAmount / totalSupply;
        tokenA.transfer(msg.sender, amtA);
        tokenB.transfer(msg.sender, amtB);
    }

    // --- Defense: require minimums for both tokens + CEI + nonReentrant
    function removeLiquiditySecure(
        uint256 lpAmount,
        uint256 minA,
        uint256 minB
    ) external nonReentrant {
        require(balanceOf[msg.sender] >= lpAmount, "Insufficient LP");
        uint256 _total = totalSupply;
        // compute amounts
        uint256 amtA = tokenA.balanceOf(address(this)) * lpAmount / _total;
        uint256 amtB = tokenB.balanceOf(address(this)) * lpAmount / _total;
        require(amtA >= minA && amtB >= minB, "Slippage too high");
        // Effects
        balanceOf[msg.sender] -= lpAmount;
        totalSupply          -= lpAmount;
        // Interaction
        tokenA.transfer(msg.sender, amtA);
        tokenB.transfer(msg.sender, amtB);
    }
}
