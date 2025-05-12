// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TVLModule - Tracks Total Value Locked (TVL) With Oracle Pricing and Attack Prevention

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

/// 📈 Oracle Interface (USD Price Feed)
contract TVLOracle {
    mapping(address => uint256) public priceUSD; // token → price in USD (1e8)

    function setPrice(address token, uint256 price) external {
        priceUSD[token] = price;
    }

    function getUSDValue(address token, uint256 amount) external view returns (uint256) {
        uint256 price = priceUSD[token];
        uint8 dec = IERC20(token).decimals();
        return (amount * price) / (10 ** dec);
    }
}

/// 🔐 TVL Vault with Oracle-Based Accounting
contract TVLVault {
    TVLOracle public oracle;
    mapping(address => uint256) public totalTokenBalance;
    mapping(address => mapping(address => uint256)) public userBalance;

    address[] public supportedTokens;
    mapping(address => bool) public isSupported;

    constructor(address _oracle) {
        oracle = TVLOracle(_oracle);
    }

    function addSupportedToken(address token) external {
        require(!isSupported[token], "Already supported");
        isSupported[token] = true;
        supportedTokens.push(token);
    }

    function deposit(address token, uint256 amt) external {
        require(isSupported[token], "Unsupported");
        require(IERC20(token).transferFrom(msg.sender, address(this), amt), "Transfer failed");
        totalTokenBalance[token] += amt;
        userBalance[msg.sender][token] += amt;
    }

    function withdraw(address token, uint256 amt) external {
        require(userBalance[msg.sender][token] >= amt, "Insufficient");
        userBalance[msg.sender][token] -= amt;
        totalTokenBalance[token] -= amt;
        IERC20(token).transfer(msg.sender, amt);
    }

    function getTotalTVL() public view returns (uint256 tvlUSD) {
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            uint256 amount = totalTokenBalance[token];
            tvlUSD += oracle.getUSDValue(token, amount);
        }
    }

    function getUserTVL(address user) public view returns (uint256 userUSD) {
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            uint256 amount = userBalance[user][token];
            userUSD += oracle.getUSDValue(token, amount);
        }
    }
}

/// 🔓 TVL Attacker (Flash Deposit / Phantom Token)
interface ITVLVault {
    function deposit(address, uint256) external;
    function withdraw(address, uint256) external;
}

contract TVLAttacker {
    function fakeTVL(ITVLVault vault, address token, uint256 amount) external {
        // Token with manipulated or 0 price
        vault.deposit(token, amount);
    }

    function flashDepositWithdraw(ITVLVault vault, address token, uint256 amount) external {
        // In a real flash loan, this would all happen in one tx
        vault.deposit(token, amount);
        vault.withdraw(token, amount);
    }
}
