// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AntiWashVolumeTracker {
    address public admin;
    mapping(address => uint256) public userVolume;
    mapping(address => mapping(address => uint256)) public volumeBetween;

    uint256 public window = 1 hours;
    struct Trade {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
    }

    event TradeLogged(address indexed from, address indexed to, uint256 amount);
    event WashTradeDetected(address indexed a1, address indexed a2, uint256 amount);

    constructor() {
        admin = msg.sender;
    }

    function logTrade(address from, address to, uint256 amount) external {
        require(from != to, "Wash trade: identical addresses");
        require(amount > 0, "Zero trade");

        volumeBetween[from][to] += amount;
        userVolume[from] += amount;

        emit TradeLogged(from, to, amount);

        if (volumeBetween[to][from] > 0) {
            emit WashTradeDetected(from, to, amount);
        }
    }

    function isSuspicious(address a1, address a2) external view returns (bool) {
        uint256 total = volumeBetween[a1][a2] + volumeBetween[a2][a1];
        uint256 diff = volumeBetween[a1][a2] > volumeBetween[a2][a1]
            ? volumeBetween[a1][a2] - volumeBetween[a2][a1]
            : volumeBetween[a2][a1] - volumeBetween[a1][a2];

        return diff < total / 10; // ~90% symmetric flow = suspicious
    }

    function reset(address from, address to) external {
        require(msg.sender == admin, "Not authorized");
        volumeBetween[from][to] = 0;
        volumeBetween[to][from] = 0;
    }
}
