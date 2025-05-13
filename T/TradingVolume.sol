// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TradingVolumeModule - Tracks Token and USD Volume Per User and Protocol

interface IERC20 {
    function decimals() external view returns (uint8);
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// 📊 Volume Oracle
contract VolumeOracle {
    mapping(address => uint256) public priceUSD; // token → price * 1e8

    function setPrice(address token, uint256 price) external {
        priceUSD[token] = price;
    }

    function getUSDValue(address token, uint256 amount) public view returns (uint256) {
        uint256 price = priceUSD[token];
        uint8 dec = IERC20(token).decimals();
        return (amount * price) / (10 ** dec);
    }
}

/// 📈 Volume Logger
contract VolumeLogger {
    VolumeOracle public oracle;
    uint256 public totalVolumeUSD;
    mapping(address => uint256) public userVolumeUSD;
    mapping(bytes32 => uint256) public pairVolume;

    event VolumeRecorded(address indexed user, address from, address to, uint256 tokenAmount, uint256 usdAmount);

    constructor(address _oracle) {
        oracle = VolumeOracle(_oracle);
    }

    function record(address user, address from, address to, uint256 amtIn) external {
        uint256 usdValue = oracle.getUSDValue(from, amtIn);
        bytes32 key = keccak256(abi.encodePacked(from, to));

        totalVolumeUSD += usdValue;
        userVolumeUSD[user] += usdValue;
        pairVolume[key] += usdValue;

        emit VolumeRecorded(user, from, to, amtIn, usdValue);
    }

    function getPairVolume(address tokenA, address tokenB) external view returns (uint256) {
        return pairVolume[keccak256(abi.encodePacked(tokenA, tokenB))];
    }

    function getUserVolume(address user) external view returns (uint256) {
        return userVolumeUSD[user];
    }
}

/// 🔁 Volume DEX
contract VolumeDEX {
    address public tokenA;
    address public tokenB;
    VolumeLogger public logger;

    constructor(address _tokenA, address _tokenB, address _logger) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        logger = VolumeLogger(_logger);
    }

    function swapAtoB(uint256 amtA) external {
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amtA), "Transfer A fail");
        uint256 amtB = amtA * 99 / 100; // 1% fee
        IERC20(tokenB).transfer(msg.sender, amtB);

        logger.record(msg.sender, tokenA, tokenB, amtA);
    }

    function swapBtoA(uint256 amtB) external {
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amtB), "Transfer B fail");
        uint256 amtA = amtB * 99 / 100;
        IERC20(tokenA).transfer(msg.sender, amtA);

        logger.record(msg.sender, tokenB, tokenA, amtB);
    }
}

/// 🔓 Volume Attacker (Wash Trader)
interface IVolumeDEX {
    function swapAtoB(uint256) external;
    function swapBtoA(uint256) external;
}

contract VolumeAttacker {
    function spamTrades(IVolumeDEX dex, uint256 rounds, uint256 amount) external {
        for (uint256 i = 0; i < rounds; i++) {
            dex.swapAtoB(amount);
            dex.swapBtoA(amount * 99 / 100);
        }
    }
}
