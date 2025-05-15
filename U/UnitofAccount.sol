// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title StableUnitVault - Vault storing balances in USD (unit of account)
interface IOracle {
    function getETHPriceUSD() external view returns (uint256); // returns price in 1e8 (e.g., 2000.00 USD)
}

contract StableUnitVault {
    IOracle public priceOracle;
    mapping(address => uint256) public usdBalance; // stored in 1e18 (USD with 18 decimals)

    event Deposited(address indexed user, uint256 ethAmount, uint256 usdValue);

    constructor(address _oracle) {
        priceOracle = IOracle(_oracle);
    }

    /// @notice Deposit ETH, convert to USD unit-of-account
    function deposit() external payable {
        require(msg.value > 0, "No ETH");

        uint256 price = priceOracle.getETHPriceUSD(); // e.g., 2000 * 1e8
        uint256 usd = (msg.value * price) / 1e8; // Convert ETH to USD with 18 decimals

        usdBalance[msg.sender] += usd;
        emit Deposited(msg.sender, msg.value, usd);
    }

    function balanceInUSD(address user) external view returns (uint256) {
        return usdBalance[user];
    }

    receive() external payable {
        deposit();
    }
}
