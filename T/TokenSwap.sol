// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenSwapModule - Secure & Vulnerable Token Swap Simulations in Solidity

// ==============================
// 🪙 Mock Token (ERC20)
// ==============================
contract MockToken {
    string public name = "Mock";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balances[msg.sender] = 1_000_000 ether;
        totalSupply = balances[msg.sender];
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Low balance");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(balances[from] >= amt && allowance[from][msg.sender] >= amt, "Denied");
        balances[from] -= amt;
        balances[to] += amt;
        allowance[from][msg.sender] -= amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🔓 Vulnerable Token Swap
// ==============================
interface IToken {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract VulnerableSwap {
    IToken public tokenA;
    IToken public tokenB;
    uint256 public rate = 2; // 1 A = 2 B

    constructor(address _a, address _b) {
        tokenA = IToken(_a);
        tokenB = IToken(_b);
    }

    function swapAtoB(uint256 amountA) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transfer(msg.sender, amountA * rate); // no slippage check
    }
}

// ==============================
// 🔐 Safe Token Swap (Validated + Slippage + Guard)
// ==============================
abstract contract ReentrancyGuard {
    bool internal locked;
    modifier nonReentrant() {
        require(!locked, "REENTRANT");
        locked = true;
        _;
        locked = false;
    }
}

contract SafeSwap is ReentrancyGuard {
    mapping(address => bool) public allowedTokens;
    IToken public tokenA;
    IToken public tokenB;
    uint256 public rate = 2; // 1 A = 2 B

    constructor(address _a, address _b) {
        tokenA = IToken(_a);
        tokenB = IToken(_b);
        allowedTokens[_a] = true;
        allowedTokens[_b] = true;
    }

    function swapAtoB(uint256 amountA, uint256 minOut) external nonReentrant {
        require(allowedTokens[address(tokenA)], "TokenA not allowed");
        require(allowedTokens[address(tokenB)], "TokenB not allowed");

        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Transfer A failed");
        uint256 out = amountA * rate;
        require(out >= minOut, "Slippage exceeded");

        require(tokenB.transfer(msg.sender, out), "Transfer B failed");
    }
}

// ==============================
// 🔓 Swap Attacker (Reentrancy / Bad Slippage)
// ==============================
interface IVulnSwap {
    function swapAtoB(uint256) external;
}

contract SwapAttacker {
    IVulnSwap public target;

    constructor(address _swap) {
        target = IVulnSwap(_swap);
    }

    function attack(uint256 amt) external {
        target.swapAtoB(amt);
    }

    receive() external payable {
        // reenter if possible (simulate callback)
    }
}
