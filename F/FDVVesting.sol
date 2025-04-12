// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPriceOracle {
    function getTokenPrice() external view returns (uint256);
}

contract FDVVesting {
    uint256 public maxSupply;
    uint256 public lockedSupply;
    uint256 public releaseRatePerDay; // in tokens
    uint256 public lastUpdated;

    IPriceOracle public oracle;

    constructor(
        uint256 _maxSupply,
        uint256 _initialLocked,
        uint256 _dailyRelease,
        address _oracle
    ) {
        maxSupply = _maxSupply;
        lockedSupply = _initialLocked;
        releaseRatePerDay = _dailyRelease;
        oracle = IPriceOracle(_oracle);
        lastUpdated = block.timestamp;
    }

    function updateLockedSupply() public {
        uint256 daysPassed = (block.timestamp - lastUpdated) / 1 days;
        uint256 toRelease = daysPassed * releaseRatePerDay;
        if (toRelease > lockedSupply) {
            lockedSupply = 0;
        } else {
            lockedSupply -= toRelease;
        }
        lastUpdated = block.timestamp;
    }

    function getFDV() external view returns (uint256) {
        uint256 price = oracle.getTokenPrice();
        return (price * maxSupply) / 1e18;
    }

    function getMarketCap() external view returns (uint256) {
        uint256 price = oracle.getTokenPrice();
        uint256 circulating = maxSupply - lockedSupply;
        return (price * circulating) / 1e18;
    }
}
