// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function transferFrom(address, address, uint256) external returns(bool);
    function transfer(address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
}

/// ------------------------------------------------------------------------
/// 1) AMM-Style Swap
/// ------------------------------------------------------------------------
contract AMMMarket is ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint112 public reserveA;
    uint112 public reserveB;

    constructor(address _a, address _b) {
        tokenA = IERC20(_a);
        tokenB = IERC20(_b);
    }

    // --- Attack: no slippage check, reads reserves only once
    function swapInsecure(uint256 amountAIn) external {
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        uint256 outB = uint256(reserveB) * amountAIn / reserveA;
        reserveA += uint112(amountAIn);
        reserveB -= uint112(outB);
        tokenB.transfer(msg.sender, outB);
    }

    // --- Defense: require minAmountOut + CEI + fresh reserves
    function swapSecure(
        uint256 amountAIn,
        uint256 minBOut
    ) external nonReentrant {
        require(amountAIn > 0, "Zero in");
        // Effects: pull in
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        uint256 a0 = reserveA;
        uint256 b0 = reserveB;
        // AMM pricing with 0.3% fee
        uint256 amountInWithFee = amountAIn * 997 / 1000;
        uint256 numerator = amountInWithFee * b0;
        uint256 denominator = a0 * 1000 + amountInWithFee;
        uint256 outB = numerator / denominator;
        require(outB >= minBOut, "Slippage too high");
        // update reserves
        reserveA = uint112(a0 + amountAIn);
        reserveB = uint112(b0 - outB);
        // Interaction
        tokenB.transfer(msg.sender, outB);
    }
}

/// ------------------------------------------------------------------------
/// 2) Limit Order Book
/// ------------------------------------------------------------------------
contract LimitOrderBook {
    struct Order {
        address user;
        bool    isBuy;
        uint256 amountIn;
        uint256 limitPrice; // tokenB per tokenA scaled 1e18
        bool    filled;
    }

    mapping(uint256 => Order) public orders;
    uint256 public nextOrder;

    // --- Attack: no price enforcement or replay guard
    function createOrderInsecure(
        bool isBuy,
        uint256 amountIn,
        uint256 limitPrice
    ) external {
        orders[nextOrder++] = Order(msg.sender, isBuy, amountIn, limitPrice, false);
    }
    function fillOrderInsecure(
        uint256 id,
        uint256 executionPrice
    ) external {
        Order storage o = orders[id];
        require(!o.filled, "Already filled");
        o.filled = true;
        // transfer logic omitted
    }

    // --- Defense: enforce price bound + prevent replay
    function createOrderSecure(
        bool isBuy,
        uint256 amountIn,
        uint256 limitPrice
    ) external {
        require(amountIn > 0, "Zero amount");
        require(limitPrice > 0, "Zero price");
        orders[nextOrder++] = Order(msg.sender, isBuy, amountIn, limitPrice, false);
    }
    function fillOrderSecure(
        uint256 id,
        uint256 executionPrice
    ) external {
        Order storage o = orders[id];
        require(!o.filled, "Already filled");
        if (o.isBuy) {
            // buying tokenA with tokenB
            require(executionPrice <= o.limitPrice, "Exec above limit");
        } else {
            // selling tokenA
            require(executionPrice >= o.limitPrice, "Exec below limit");
        }
        o.filled = true;
        // transfer logic omitted
    }
}

/// ------------------------------------------------------------------------
/// 3) Algorithmic Supply Adjustment
/// ------------------------------------------------------------------------
interface ITWAP {
    function getTwapPrice() external view returns (uint256);
}

contract SupplyAdjuster is ReentrancyGuard {
    address public owner;
    uint256 public lastRebase;
    uint256 public minRebaseInterval; // e.g. 1 hour
    uint256 public minSupply;
    uint256 public maxSupply;
    ITWAP[] public oracles;
    uint256 public totalSupply;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        ITWAP[] memory _oracles,
        uint256 _minInterval,
        uint256 _minSupply,
        uint256 _maxSupply
    ) {
        oracles = _oracles;
        owner = msg.sender;
        minRebaseInterval = _minInterval;
        minSupply = _minSupply;
        maxSupply = _maxSupply;
    }

    // --- Attack: naive rebase on spot price, no TWAP or cooldown
    function rebaseInsecure(int256 supplyDelta) external {
        totalSupply = uint256(int256(totalSupply) + supplyDelta);
    }

    // --- Defense: TWAP aggregate + cooldown + bounds
    function rebaseSecure(int256 supplyDelta) external onlyOwner nonReentrant {
        require(
            block.timestamp >= lastRebase + minRebaseInterval,
            "Rebase too soon"
        );
        // aggregate TWAP
        uint256 sum;
        uint256 n = oracles.length;
        require(n > 0, "No oracles");
        for (uint i = 0; i < n; i++) {
            uint256 p = oracles[i].getTwapPrice();
            sum += p;
        }
        uint256 price = sum / n;
        require(price > 0, "Invalid price");
        // compute new supply and enforce bounds
        int256 newSupply = int256(totalSupply) + supplyDelta;
        require(
            newSupply >= int256(minSupply) && newSupply <= int256(maxSupply),
            "Supply out of bounds"
        );
        totalSupply = uint256(newSupply);
        lastRebase = block.timestamp;
    }
}
