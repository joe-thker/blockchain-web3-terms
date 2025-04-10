// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Liquidity Bootstrapping Pool (LBP) Simulator
contract LBPSimulator {
    uint256 public tokenWeightStart = 95; // 95%
    uint256 public tokenWeightEnd = 20;   // 20%
    uint256 public baseWeightStart = 5;   // 5%
    uint256 public baseWeightEnd = 80;    // 80%

    uint256 public startTime;
    uint256 public duration = 3 days;

    constructor() {
        startTime = block.timestamp;
    }

    function getCurrentWeights() public view returns (uint256 tokenWeight, uint256 baseWeight) {
        uint256 elapsed = block.timestamp - startTime;
        if (elapsed >= duration) return (tokenWeightEnd, baseWeightEnd);

        uint256 progress = (elapsed * 1e18) / duration;

        tokenWeight = tokenWeightStart - ((tokenWeightStart - tokenWeightEnd) * progress) / 1e18;
        baseWeight = baseWeightStart + ((baseWeightEnd - baseWeightStart) * progress) / 1e18;
    }

    function getCurrentPrice(uint256 tokenReserve, uint256 baseReserve) external view returns (uint256 price) {
        (uint256 tokenWeight, uint256 baseWeight) = getCurrentWeights();

        // Balancer-style weighted AMM price formula:
        // P = (baseReserve / baseWeight) / (tokenReserve / tokenWeight)
        price = (baseReserve * tokenWeight * 1e18) / (baseWeight * tokenReserve);
    }
}
