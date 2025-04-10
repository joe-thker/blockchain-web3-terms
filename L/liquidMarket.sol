// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Liquidity Pool Simulator (Uniswap v2-style)
contract LiquidMarketSim {
    uint256 public tokenReserve = 100_000 ether; // ERC20-like token
    uint256 public ethReserve = 100 ether;       // ETH reserve in wei

    function getPriceImpact(uint256 ethIn) public view returns (uint256 tokenOut) {
        require(ethIn > 0, "Invalid input");

        uint256 newEthReserve = ethReserve + ethIn;
        uint256 newTokenReserve = (ethReserve * tokenReserve) / newEthReserve;
        tokenOut = tokenReserve - newTokenReserve;
    }

    function simulateTrade(uint256 ethIn) external view returns (uint256 tokenReceived, uint256 priceImpactBps) {
        uint256 tokenOut = getPriceImpact(ethIn);
        uint256 idealRate = (tokenReserve * 1e18) / ethReserve;
        uint256 actualRate = (tokenOut * 1e18) / ethIn;

        priceImpactBps = ((idealRate - actualRate) * 10_000) / idealRate;
        return (tokenOut, priceImpactBps); // Output tokens and slippage in basis points
    }
}
