// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TickerSymbolModule - Attack and Defense for Ticker Symbol-Based Vulnerabilities

// ==============================
// 🔓 Fake Ticker Token (Spoof)
// ==============================
contract FakeTickerToken {
    string public name = "Fake USD Coin";
    string public symbol = "USDC"; // Looks like the real USDC
    uint8 public decimals = 6;
    uint256 public totalSupply = 1_000_000 * 10**6;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Insufficient");
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
// 🔓 Vulnerable Contract: Symbol-Based Swap
// ==============================
interface ISymbolToken {
    function symbol() external view returns (string memory);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract SymbolFilteredSwap {
    function swap(ISymbolToken token, uint256 amount) external {
        require(
            keccak256(abi.encodePacked(token.symbol())) == keccak256("USDC"),
            "Symbol not allowed"
        );
        token.transferFrom(msg.sender, address(this), amount);
    }
}

// ==============================
// 🔐 Secure Contract: Address-Based Swap + Registry Check
// ==============================
interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
}

contract SafeSymbolSwap {
    address public registry;
    address public owner;

    constructor(address _registry) {
        registry = _registry;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Denied");
        _;
    }

    function swap(address token, string memory expectedSymbol, uint256 amount) external {
        require(SymbolRegistry(registry).verify(token, expectedSymbol), "Mismatch");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function allowSymbol(address token, string memory symbol) external onlyOwner {
        SymbolRegistry(registry).register(symbol, token);
    }
}

// ==============================
// 🧱 Symbol Registry (Admin Verified)
// ==============================
contract SymbolRegistry {
    mapping(string => address) public symbolToAddress;
    mapping(address => string) public addressToSymbol;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function register(string memory symbol, address token) external {
        require(msg.sender == admin, "Not admin");
        symbolToAddress[symbol] = token;
        addressToSymbol[token] = symbol;
    }

    function verify(address token, string memory symbol) external view returns (bool) {
        return symbolToAddress[symbol] == token;
    }
}
