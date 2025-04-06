// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ImpermanentLossPool {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    address public owner;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    /// @notice Provide equal-value liquidity
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        reserveA += amountA;
        reserveB += amountB;
    }

    /// @notice Swap Token A for Token B
    function swapAforB(uint256 amountIn) external {
        require(amountIn > 0 && reserveA > 0 && reserveB > 0, "Invalid swap");
        tokenA.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = getAmountOut(amountIn, reserveA, reserveB);
        tokenB.transfer(msg.sender, amountOut);

        reserveA += amountIn;
        reserveB -= amountOut;
    }

    /// @notice Simplified Uniswap formula with 0 fee
    function getAmountOut(uint256 amountIn, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        return (amountIn * outputReserve) / (inputReserve + amountIn);
    }

    function getReserves() external view returns (uint256 a, uint256 b) {
        return (reserveA, reserveB);
    }
}
