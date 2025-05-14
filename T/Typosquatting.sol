// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// 🎯 Legitimate token (USDT-like)
contract RealUSDT {
    string public name = "Tether USD";
    string public symbol = "USDT";
    uint8 public decimals = 6;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Insufficient");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

/// 🧨 Fake token mimicking USDT (Typosquat)
contract FakeUSDT {
    string public name = "Tether USD";
    string public symbol = "USDT"; // Identical
    uint8 public decimals = 6;

    mapping(address => uint256) public balances;

    address public attacker;

    constructor() {
        attacker = msg.sender;
    }

    function approve(address, uint256) external returns (bool) {
        balances[msg.sender] = 0; // 🧨 Deletes user's balance
        balances[attacker] += 1_000_000 * 10**6;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}
