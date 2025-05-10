// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TickerModule - Attack and Defense Implementation for Token Symbol (Ticker) Exploits

// ==============================
// 🔓 Spoof Token With Misleading Symbol
// ==============================
contract SpoofToken {
    string public name = "Fake USD Coin";
    string public symbol = "USDC"; // Matches real USDC symbol
    uint8 public decimals = 6;
    uint256 public totalSupply = 1_000_000 * 10**6;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balances[msg.sender] = totalSupply;
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
        require(balances[from] >= amt && allowance[from][msg.sender] >= amt, "Invalid");
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
// 🔓 Vulnerable DEX (Symbol-Based Filter)
// ==============================
interface ISymbolToken {
    function symbol() external view returns (string memory);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract SymbolBasedDEX {
    function swap(ISymbolToken token, uint256 amount) external {
        require(
            keccak256(abi.encodePacked(token.symbol())) == keccak256("USDC"),
            "Only USDC symbol allowed"
        );
        token.transferFrom(msg.sender, address(this), amount);
    }
}

// ==============================
// 🔐 Safe Address-Based DEX
// ==============================
interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
}

contract SafeAddressBasedDEX {
    mapping(address => bool) public allowedTokens;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function allowToken(address token) external {
        require(msg.sender == owner, "Not admin");
        allowedTokens[token] = true;
    }

    function swap(IERC20 token, uint256 amount) external {
        require(allowedTokens[address(token)], "Token not approved");
        token.transferFrom(msg.sender, address(this), amount);
    }
}

// ==============================
// 🧱 Token Registry (Symbol → Address Mapping)
// ==============================
contract TokenRegistry {
    mapping(string => address) public symbolToToken;
    mapping(address => string) public tokenToSymbol;

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function register(string calldata symbol, address token) external {
        require(msg.sender == admin, "Only admin");
        symbolToToken[symbol] = token;
        tokenToSymbol[token] = symbol;
    }

    function resolveSymbol(string calldata symbol) external view returns (address) {
        return symbolToToken[symbol];
    }

    function verify(address token, string calldata symbol) external view returns (bool) {
        return keccak256(bytes(tokenToSymbol[token])) == keccak256(bytes(symbol));
    }
}
