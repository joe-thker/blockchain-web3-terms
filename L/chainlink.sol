// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

/// @title Chainlink Price Consumer – ETH/USD
contract ChainlinkPriceConsumer {
    AggregatorV3Interface public priceFeed;

    constructor(address _aggregator) {
        priceFeed = AggregatorV3Interface(_aggregator);
    }

    function getLatestPrice() external view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price; // Price with 8 decimals
    }
}
