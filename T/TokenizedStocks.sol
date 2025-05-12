// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenizedStockModule - Stock Representation with Custody + Oracle + Compliance

// ==============================
// 📊 Stock Token (ERC20 with Custodian Control)
// ==============================
contract StockToken {
    string public name = "Tokenized AAPL";
    string public symbol = "tAAPL";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public custodian;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    modifier onlyCustodian() {
        require(msg.sender == custodian, "Not custodian");
        _;
    }

    constructor(address _custodian) {
        custodian = _custodian;
    }

    function mint(address to, uint256 amt) external onlyCustodian {
        balances[to] += amt;
        totalSupply += amt;
    }

    function burn(address from, uint256 amt) external onlyCustodian {
        require(balances[from] >= amt, "Too much burn");
        balances[from] -= amt;
        totalSupply -= amt;
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
        require(balances[from] >= amt && allowance[from][msg.sender] >= amt, "Not allowed");
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
// 🏛️ Custodian Contract
// ==============================
contract Custodian {
    address public admin;
    StockToken public token;

    constructor(address _token) {
        admin = msg.sender;
        token = StockToken(_token);
    }

    function issue(address to, uint256 amt) external {
        require(msg.sender == admin, "Not admin");
        token.mint(to, amt);
    }

    function redeem(address from, uint256 amt) external {
        require(msg.sender == admin, "Not admin");
        token.burn(from, amt);
    }
}

// ==============================
// 🧮 Oracle: Price Feed Simulation
// ==============================
contract StockPriceOracle {
    uint256 public lastPrice; // e.g., $183.45 = 18345 (2 decimals)

    function updatePrice(uint256 newPrice) external {
        lastPrice = newPrice;
    }

    function getPrice() external view returns (uint256) {
        return lastPrice;
    }
}

// ==============================
// 🔓 Fake Issuer Attack
// ==============================
interface IStockToken {
    function mint(address, uint256) external;
}

contract FakeStockIssuer {
    function tryMint(IStockToken token, address to, uint256 amt) external {
        token.mint(to, amt); // should fail if not custodian
    }
}
