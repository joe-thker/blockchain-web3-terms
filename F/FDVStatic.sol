// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPriceOracle {
    function getTokenPrice() external view returns (uint256); // 1e18 = $1.00
}

contract FDVStatic {
    address public owner;
    uint256 public immutable maxSupply; // total planned token supply
    IPriceOracle public priceOracle;

    constructor(uint256 _maxSupply, address _oracle) {
        owner = msg.sender;
        maxSupply = _maxSupply;
        priceOracle = IPriceOracle(_oracle);
    }

    function getFDV() public view returns (uint256) {
        uint256 price = priceOracle.getTokenPrice(); // 1e18 format
        return (price * maxSupply) / 1e18;
    }
}
