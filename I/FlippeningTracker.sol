// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
}

interface IOracle {
    function getPrice() external view returns (uint256); // returns price in USD (scaled to 1e8)
}

/**
 * @title FlippeningTracker
 * @dev Tracks whether one token has surpassed another in market cap.
 */
contract FlippeningTracker {
    address public tokenA;
    address public tokenB;
    IOracle public oracleA;
    IOracle public oracleB;

    event FlippeningDetected(
        address indexed flipper,
        uint256 newMarketCap,
        address indexed flipped,
        uint256 oldMarketCap
    );

    constructor(
        address _tokenA,
        address _oracleA,
        address _tokenB,
        address _oracleB
    ) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        oracleA = IOracle(_oracleA);
        oracleB = IOracle(_oracleB);
    }

    function getMarketCap(address token, IOracle oracle) public view returns (uint256) {
        uint256 supply = IERC20(token).totalSupply();
        uint256 price = oracle.getPrice(); // scaled to 1e8
        return (supply * price) / 1e8;
    }

    /// ✅ FIX: Visibility added
    function checkFlippening() public view returns (bool flipped, uint256 capA, uint256 capB) {
        capA = getMarketCap(tokenA, oracleA);
        capB = getMarketCap(tokenB, oracleB);
        flipped = capA > capB;
    }

    function announceFlippening() external {
        (bool flipped, uint256 capA, uint256 capB) = checkFlippening();
        require(flipped, "No flippening yet");

        emit FlippeningDetected(tokenA, capA, tokenB, capB);
    }
}
