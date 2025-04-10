// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
}

interface IOracle {
    function getPrice() external view returns (uint256); // USD price scaled 1e8
}

contract FlippeningMarketCap {
    address public tokenA;
    address public tokenB;
    IOracle public oracleA;
    IOracle public oracleB;

    event FlippeningDetected(uint256 capA, uint256 capB);

    constructor(address _a, address _oa, address _b, address _ob) {
        tokenA = _a;
        tokenB = _b;
        oracleA = IOracle(_oa);
        oracleB = IOracle(_ob);
    }

    function getCap(address token, IOracle oracle) public view returns (uint256) {
        return (IERC20(token).totalSupply() * oracle.getPrice()) / 1e8;
    }

    function check() public view returns (bool flipped) {
        uint256 a = getCap(tokenA, oracleA);
        uint256 b = getCap(tokenB, oracleB);
        flipped = a > b;
    }

    function announce() external {
        require(check(), "No flippening yet");
        emit FlippeningDetected(getCap(tokenA, oracleA), getCap(tokenB, oracleB));
    }
}
