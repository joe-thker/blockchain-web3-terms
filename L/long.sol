// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract LongPosition {
    IERC20 public collateralToken; // USDC
    IERC20 public syntheticETH;    // sETH

    uint256 public ethPrice = 2000e18; // 1 ETH = $2000
    mapping(address => uint256) public collateralBalance;
    mapping(address => uint256) public mintedSETH;

    constructor(address _collateralToken, address _syntheticETH) {
        collateralToken = IERC20(_collateralToken);
        syntheticETH = IERC20(_syntheticETH);
    }

    function openLong(uint256 usdcAmount) external {
        require(collateralToken.transferFrom(msg.sender, address(this), usdcAmount), "Transfer failed");

        uint256 sETHAmount = (usdcAmount * 1e18) / ethPrice; // Mint sETH at current price
        collateralBalance[msg.sender] += usdcAmount;
        mintedSETH[msg.sender] += sETHAmount;

        syntheticETH.transfer(msg.sender, sETHAmount);
    }

    function closeLong(uint256 sETHAmount) external {
        require(mintedSETH[msg.sender] >= sETHAmount, "Not enough sETH");

        uint256 usdValue = (sETHAmount * ethPrice) / 1e18;
        require(collateralBalance[msg.sender] >= usdValue, "Not enough collateral");

        syntheticETH.transferFrom(msg.sender, address(this), sETHAmount);
        mintedSETH[msg.sender] -= sETHAmount;
        collateralBalance[msg.sender] -= usdValue;

        collateralToken.transfer(msg.sender, usdValue);
    }
}
