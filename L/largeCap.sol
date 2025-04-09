// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IAggregator {
    function latestAnswer() external view returns (int256);
}

interface IERC20Supply {
    function totalSupply() external view returns (uint256);
}

/// @title Large Cap Evaluator
contract LargeCapTracker {
    uint256 public constant LARGE_CAP_THRESHOLD = 10_000_000_000e18; // $10B

    function isLargeCap(address priceFeed, address tokenAddress) external view returns (bool) {
        int256 price = IAggregator(priceFeed).latestAnswer();
        require(price > 0, "Invalid price");

        uint256 supply = IERC20Supply(tokenAddress).totalSupply();
        uint256 marketCap = (uint256(price) * supply) / 1e8; // Chainlink decimals

        return marketCap >= LARGE_CAP_THRESHOLD;
    }
}
