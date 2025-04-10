// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IHashFeed {
    function getHashrate(address chain) external view returns (uint256);
}

contract FlippeningHashrate {
    address public btc;
    address public eth;
    IHashFeed public hash;

    constructor(address _btc, address _eth, address _oracle) {
        btc = _btc;
        eth = _eth;
        hash = IHashFeed(_oracle);
    }

    function flipped() external view returns (bool) {
        return hash.getHashrate(eth) > hash.getHashrate(btc);
    }
}
