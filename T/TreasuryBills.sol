// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TBillModule - Tokenized T-Bill Vault with Oracle-Based Yield Reflection

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// 🧠 T-Bill Oracle
contract MockOracle {
    uint256 public pricePerShare = 1e18; // starts at $1.00

    function setPrice(uint256 _price) external {
        pricePerShare = _price;
    }

    function getPrice() external view returns (uint256) {
        return pricePerShare;
    }
}

/// 🪙 T-Bill Vault Token (Yield-Bearing)
contract TBillToken {
    string public name = "Tokenized T-Bill";
    string public symbol = "TBT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public vault;
    mapping(address => uint256) public balances;

    constructor(address _vault) {
        vault = _vault;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function mint(address to, uint256 amt) external onlyVault {
        balances[to] += amt;
        totalSupply += amt;
    }

    function burn(address from, uint256 amt) external onlyVault {
        require(balances[from] >= amt, "Low balance");
        balances[from] -= amt;
        totalSupply -= amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Low balance");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

/// 💰 T-Bill Vault (USDC Deposits → Off-Chain T-Bills)
contract TBillVault {
    IERC20 public usdc;
    TBillToken public tbt;
    MockOracle public oracle;
    address public admin;

    constructor(address _usdc, address _oracle) {
        usdc = IERC20(_usdc);
        oracle = MockOracle(_oracle);
        tbt = new TBillToken(address(this));
        admin = msg.sender;
    }

    function deposit(uint256 amount) external {
        require(usdc.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        uint256 shares = amount * 1e18 / oracle.getPrice();
        tbt.mint(msg.sender, shares);
    }

    function withdraw(uint256 shares) external {
        uint256 amount = shares * oracle.getPrice() / 1e18;
        tbt.burn(msg.sender, shares);
        require(usdc.transfer(msg.sender, amount), "Transfer failed");
    }

    function vaultValue() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    function tbtToUSDC(uint256 shares) external view returns (uint256) {
        return shares * oracle.getPrice() / 1e18;
    }
}

/// 🧨 T-Bill Attacker (Spoof or Overclaim)
interface ITBillVault {
    function deposit(uint256) external;
    function withdraw(uint256) external;
}

contract TBillAttacker {
    function fakeOracle(MockOracle oracle, uint256 badPrice) external {
        oracle.setPrice(badPrice); // Manipulate valuation
    }

    function exploitWithdraw(ITBillVault vault, uint256 shares) external {
        vault.withdraw(shares); // Tries to withdraw overvalued T-Bills
    }
}
