// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Liquidity Depth Simulator (x*y=k pool)
contract LiquiditySimulator {
    uint256 public tokenReserve = 100_000 ether;
    uint256 public ethReserve = 1_000 ether;

    function simulateSwapETHToToken(uint256 ethIn) external view returns (uint256 tokenOut) {
        uint256 newEthReserve = ethReserve + ethIn;
        uint256 newTokenReserve = (ethReserve * tokenReserve) / newEthReserve;
        tokenOut = tokenReserve - newTokenReserve;
    }

    function getPriceImpact(uint256 ethIn) external view returns (uint256 impactBps) {
        uint256 idealRate = (tokenReserve * 1e18) / ethReserve;
        uint256 tokenOut = this.simulateSwapETHToToken(ethIn);
        uint256 actualRate = (tokenOut * 1e18) / ethIn;
        impactBps = ((idealRate - actualRate) * 10_000) / idealRate;
    }
}
