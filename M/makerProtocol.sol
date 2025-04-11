// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burnFrom(address, uint256) external;
}

contract MiniMakerVault {
    IERC20 public dai;
    uint256 public ethPrice = 2000e18; // e.g., from oracle (in USD with 1e18 precision)
    uint256 public collateralizationRatio = 150; // 150%

    struct Vault {
        uint256 collateralETH;
        uint256 debtDAI;
    }

    mapping(address => Vault) public vaults;

    constructor(address _dai) {
        dai = IERC20(_dai);
    }

    function depositAndMint() external payable {
        require(msg.value > 0, "No ETH sent");

        uint256 mintableDAI = (msg.value * ethPrice) / 1e18;
        mintableDAI = (mintableDAI * 100) / collateralizationRatio; // Apply collateral ratio

        vaults[msg.sender].collateralETH += msg.value;
        vaults[msg.sender].debtDAI += mintableDAI;

        dai.mint(msg.sender, mintableDAI);
    }

    function repayAndWithdraw(uint256 daiAmount) external {
        Vault storage v = vaults[msg.sender];
        require(v.debtDAI >= daiAmount, "Too much repay");

        uint256 ethToReturn = (daiAmount * 1e18 * collateralizationRatio) / ethPrice / 100;

        v.debtDAI -= daiAmount;
        v.collateralETH -= ethToReturn;

        dai.burnFrom(msg.sender, daiAmount);
        payable(msg.sender).transfer(ethToReturn);
    }

    function getVaultValue(address user) external view returns (uint256 daiValue) {
        Vault storage v = vaults[user];
        return (v.collateralETH * ethPrice) / 1e18;
    }

    function getHealthFactor(address user) external view returns (uint256) {
        Vault storage v = vaults[user];
        if (v.debtDAI == 0) return type(uint256).max;
        return (v.collateralETH * ethPrice * 100) / (v.debtDAI * 1e18);
    }
}
