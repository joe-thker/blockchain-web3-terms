// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Type 1: Classic Price Divergence AMM
contract ILType1_PriceDivergence {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        reserveA += amountA;
        reserveB += amountB;
    }

    function swapAforB(uint256 amountIn) external {
        tokenA.transferFrom(msg.sender, address(this), amountIn);
        uint256 amountOut = (amountIn * reserveB) / (reserveA + amountIn);
        tokenB.transfer(msg.sender, amountOut);
        reserveA += amountIn;
        reserveB -= amountOut;
    }
}

/// @title Type 2: Volatile Token Pair AMM
contract ILType2_VolatilePair is ILType1_PriceDivergence {
    constructor(address _tokenA, address _tokenB) ILType1_PriceDivergence(_tokenA, _tokenB) {}
}

/// @title Type 3: Asymmetric Swap Pressure
contract ILType3_AsymmetricSwap is ILType1_PriceDivergence {
    constructor(address _tokenA, address _tokenB) ILType1_PriceDivergence(_tokenA, _tokenB) {}

    function simulatePressure(uint256 amountIn) external {
        swapAforB(amountIn);
    }
}

/// @title Type 4: Early Withdrawal with LP Shares
contract ILType4_EarlyWithdrawal {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;

    mapping(address => uint256) public lpShares;
    uint256 public totalShares;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        uint256 shares = amountA + amountB;
        lpShares[msg.sender] += shares;
        totalShares += shares;
        reserveA += amountA;
        reserveB += amountB;
    }

    function swapAforB(uint256 amountIn) external {
        tokenA.transferFrom(msg.sender, address(this), amountIn);
        uint256 amountOut = (amountIn * reserveB) / (reserveA + amountIn);
        tokenB.transfer(msg.sender, amountOut);
        reserveA += amountIn;
        reserveB -= amountOut;
    }

    function withdraw() external {
        uint256 share = lpShares[msg.sender];
        require(share > 0, "No LP");
        uint256 amountA = (reserveA * share) / totalShares;
        uint256 amountB = (reserveB * share) / totalShares;
        lpShares[msg.sender] = 0;
        totalShares -= share;
        reserveA -= amountA;
        reserveB -= amountB;
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }
}

/// @title Type 5: Permanent Loss after Withdrawal
contract ILType5_PermanentLoss is ILType4_EarlyWithdrawal {
    constructor(address _tokenA, address _tokenB) ILType4_EarlyWithdrawal(_tokenA, _tokenB) {}
}
