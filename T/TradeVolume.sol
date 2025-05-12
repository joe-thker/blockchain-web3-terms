// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TradeVolumeModule - Track Per-User and Per-Pair Trade Volume Securely

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// 🧮 Volume Registry (Per-User, Per-Pair, Global)
contract VolumeRegistry {
    uint256 public totalVolume;
    mapping(address => uint256) public userVolume;
    mapping(bytes32 => uint256) public pairVolume;

    event VolumeLogged(address indexed user, address fromToken, address toToken, uint256 amountIn, uint256 amountOut);

    function logTrade(address user, address fromToken, address toToken, uint256 amtIn, uint256 amtOut) external {
        totalVolume += amtIn;
        userVolume[user] += amtIn;

        bytes32 pairKey = keccak256(abi.encodePacked(fromToken, toToken));
        pairVolume[pairKey] += amtIn;

        emit VolumeLogged(user, fromToken, toToken, amtIn, amtOut);
    }

    function getUserVolume(address user) external view returns (uint256) {
        return userVolume[user];
    }

    function getPairVolume(address tokenA, address tokenB) external view returns (uint256) {
        return pairVolume[keccak256(abi.encodePacked(tokenA, tokenB))];
    }
}

/// 🔁 Trade DEX Simulated
contract TradeDEX {
    address public tokenA;
    address public tokenB;
    VolumeRegistry public registry;

    constructor(address _tokenA, address _tokenB, address _registry) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        registry = VolumeRegistry(_registry);
    }

    function swapAtoB(uint256 amtIn) external {
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amtIn), "Transfer failed");
        uint256 amtOut = amtIn * 99 / 100; // 1% fee
        IERC20(tokenB).transfer(msg.sender, amtOut);

        registry.logTrade(msg.sender, tokenA, tokenB, amtIn, amtOut);
    }

    function swapBtoA(uint256 amtIn) external {
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amtIn), "Transfer failed");
        uint256 amtOut = amtIn * 99 / 100;
        IERC20(tokenA).transfer(msg.sender, amtOut);

        registry.logTrade(msg.sender, tokenB, tokenA, amtIn, amtOut);
    }
}

/// 🔓 Volume Attacker (Wash + Spoof Simulation)
interface ITradeDEX {
    function swapAtoB(uint256) external;
    function swapBtoA(uint256) external;
}

contract VolumeAttacker {
    function washTrade(ITradeDEX dex, uint256 rounds, uint256 amt) external {
        for (uint256 i = 0; i < rounds; i++) {
            dex.swapAtoB(amt);
            dex.swapBtoA(amt * 99 / 100); // simulate slippage loop
        }
    }
}
