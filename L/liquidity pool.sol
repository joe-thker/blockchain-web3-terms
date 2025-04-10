// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

/// @title Simple Liquidity Pool (Uniswap v2-style)
contract LiquidityPool {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 mintAmount;
        if (totalLiquidity == 0) {
            mintAmount = sqrt(amountA * amountB);
        } else {
            mintAmount = min((amountA * totalLiquidity) / reserveA, (amountB * totalLiquidity) / reserveB);
        }

        liquidity[msg.sender] += mintAmount;
        totalLiquidity += mintAmount;

        reserveA += amountA;
        reserveB += amountB;
    }

    function removeLiquidity(uint256 lpAmount) external {
        require(liquidity[msg.sender] >= lpAmount, "Not enough LP tokens");
        uint256 amountA = (lpAmount * reserveA) / totalLiquidity;
        uint256 amountB = (lpAmount * reserveB) / totalLiquidity;

        liquidity[msg.sender] -= lpAmount;
        totalLiquidity -= lpAmount;

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }

    function swap(address inputToken, uint256 inputAmount) external {
        require(inputToken == address(tokenA) || inputToken == address(tokenB), "Invalid token");

        bool isAToB = inputToken == address(tokenA);
        IERC20 input = isAToB ? tokenA : tokenB;
        IERC20 output = isAToB ? tokenB : tokenA;

        input.transferFrom(msg.sender, address(this), inputAmount);

        uint256 inputReserve = isAToB ? reserveA : reserveB;
        uint256 outputReserve = isAToB ? reserveB : reserveA;

        uint256 inputAmountWithFee = (inputAmount * 997) / 1000; // 0.3% fee
        uint256 outputAmount = (inputAmountWithFee * outputReserve) / (inputReserve + inputAmountWithFee);

        require(outputAmount > 0, "Insufficient output");

        if (isAToB) {
            reserveA += inputAmount;
            reserveB -= outputAmount;
        } else {
            reserveB += inputAmount;
            reserveA -= outputAmount;
        }

        output.transfer(msg.sender, outputAmount);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}
