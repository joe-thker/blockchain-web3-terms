// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPriceFeed {
    function getTokenPrice() external view returns (uint256);
}

contract FDVPerPool {
    struct Pool {
        string name;
        uint256 allocation;
    }

    Pool[] public pools;
    uint256 public totalSupply;
    IPriceFeed public priceFeed;

    constructor(address _oracle) {
        priceFeed = IPriceFeed(_oracle);
    }

    function addPool(string memory name, uint256 allocation) external {
        pools.push(Pool(name, allocation));
        totalSupply += allocation;
    }

    function getFDV() external view returns (uint256) {
        uint256 price = priceFeed.getTokenPrice();
        return (price * totalSupply) / 1e18;
    }

    function getPoolFDV(uint256 poolId) external view returns (uint256) {
        uint256 price = priceFeed.getTokenPrice();
        return (price * pools[poolId].allocation) / 1e18;
    }

    function poolCount() external view returns (uint256) {
        return pools.length;
    }
}
