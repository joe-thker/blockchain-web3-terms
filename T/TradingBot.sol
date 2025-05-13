// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TradingBotModule - Bot Simulation with Arbitrage, Sniping, and Defense

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// 🔁 Simple DEX (Fixed Rate)
contract SimpleDEX {
    address public tokenA;
    address public tokenB;
    uint256 public price = 2; // 1 A = 2 B
    uint256 public totalTraded;

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function swapAtoB(uint256 amtA, uint256 minOut) external {
        uint256 outB = amtA * price;
        require(outB >= minOut, "Slippage too high");
        IERC20(tokenA).transferFrom(msg.sender, address(this), amtA);
        IERC20(tokenB).transfer(msg.sender, outB);
        totalTraded += amtA;
    }
}

/// 🤖 Arbitrage Bot (DEX A vs DEX B)
interface IDex {
    function swapAtoB(uint256 amt, uint256 minOut) external;
}

contract TradingBot {
    IDex public dex1;
    IDex public dex2;
    address public owner;

    constructor(address _dex1, address _dex2) {
        dex1 = IDex(_dex1);
        dex2 = IDex(_dex2);
        owner = msg.sender;
    }

    function executeArbitrage(uint256 amt, uint256 minOut1, uint256 minOut2) external {
        require(msg.sender == owner, "Not owner");
        dex1.swapAtoB(amt, minOut1); // Buy tokenB cheap
        dex2.swapAtoB(amt, minOut2); // Sell tokenB at profit
    }
}

/// 🎯 Sniper Bot (Instant Buy)
contract SniperBot {
    IDex public target;
    address public owner;

    constructor(address _dex) {
        target = _dex;
        owner = msg.sender;
    }

    function snipe(uint256 amountIn, uint256 minOut) external {
        require(msg.sender == owner, "Not owner");
        target.swapAtoB(amountIn, minOut);
    }
}

/// 🛡️ Bot Defense DEX (Anti-reentrancy + Cooldown)
abstract contract ReentrancyGuard {
    bool private locked;
    modifier nonReentrant() {
        require(!locked, "Reentrant blocked");
        locked = true;
        _;
        locked = false;
    }
}

contract BotDefenseDEX is ReentrancyGuard {
    address public tokenA;
    address public tokenB;
    mapping(address => uint256) public lastTradeBlock;

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function swapAtoB(uint256 amt, uint256 minOut) external nonReentrant {
        require(block.number > lastTradeBlock[msg.sender], "Cooldown active");
        uint256 out = amt * 2;
        require(out >= minOut, "Slippage!");
        IERC20(tokenA).transferFrom(msg.sender, address(this), amt);
        IERC20(tokenB).transfer(msg.sender, out);
        lastTradeBlock[msg.sender] = block.number;
    }
}
