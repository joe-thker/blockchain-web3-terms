// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SymbolAttackModule - Attack and Defense Simulation for Symbol Spoofing in Web3

// ==============================
// 🔓 Fake Token with Spoofed Symbol
// ==============================
interface IERC20 {
    function symbol() external view returns (string memory);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
}

contract FakeUSDC {
    string public name = "Fake USD Coin";
    string public symbol = "USDC"; // Spoofed legit symbol
    uint8 public decimals = 6;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    constructor(uint256 _initial) {
        balances[msg.sender] = _initial;
        totalSupply = _initial;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient");
        balances[msg.sender] -= value;
        balances[to] += value;
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowances[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balances[from] >= value, "Low balance");
        require(allowances[from][msg.sender] >= value, "Not allowed");
        balances[from] -= value;
        balances[to] += value;
        allowances[from][msg.sender] -= value;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🔥 Vulnerable DEX Using Symbol()
// ==============================
contract TrustedDEX {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Vulnerable: uses token.symbol() for validation
    function trade(IERC20 token, uint256 amount) external {
        require(
            keccak256(abi.encodePacked(token.symbol())) == keccak256("USDC"),
            "Token symbol not accepted"
        );
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
}

// ==============================
// 🔐 Hardened DEX Using Address
// ==============================
contract SafeDEX {
    address public owner;
    mapping(address => bool) public allowedTokens;

    constructor() {
        owner = msg.sender;
    }

    function setToken(address token, bool approved) external {
        require(msg.sender == owner, "Not owner");
        allowedTokens[token] = approved;
    }

    function trade(IERC20 token, uint256 amount) external {
        require(allowedTokens[address(token)], "Token not approved");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
}

// ==============================
// 🧱 Trusted Token Registry (Optional Extension)
// ==============================
contract TrustedTokenRegistry {
    mapping(bytes32 => address) public symbolToToken;
    mapping(address => string) public tokenToSymbol;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function register(address token, string memory symbol) external {
        require(msg.sender == owner, "Only owner");
        symbolToToken[keccak256(abi.encodePacked(symbol))] = token;
        tokenToSymbol[token] = symbol;
    }

    function resolve(string memory symbol) external view returns (address) {
        return symbolToToken[keccak256(abi.encodePacked(symbol))];
    }

    function verify(address token, string memory symbol) external view returns (bool) {
        return (keccak256(bytes(tokenToSymbol[token])) == keccak256(bytes(symbol)));
    }
}
