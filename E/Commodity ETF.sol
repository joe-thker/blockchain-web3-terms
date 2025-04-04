// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ Add the IERC20 interface here
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CommodityETF {
    IERC20 public wbtc;
    IERC20 public sGold;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    event Minted(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);

    constructor(address _wbtc, address _sGold) {
        wbtc = IERC20(_wbtc);
        sGold = IERC20(_sGold);
    }

    function mint(uint256 wbtcAmt, uint256 sGoldAmt) external {
        require(wbtcAmt == sGoldAmt, "Provide equal amounts");

        require(wbtc.transferFrom(msg.sender, address(this), wbtcAmt), "WBTC transfer failed");
        require(sGold.transferFrom(msg.sender, address(this), sGoldAmt), "sGOLD transfer failed");

        uint256 minted = wbtcAmt + sGoldAmt;
        balanceOf[msg.sender] += minted;
        totalSupply += minted;

        emit Minted(msg.sender, minted);
    }

    function redeem(uint256 etfAmount) external {
        require(balanceOf[msg.sender] >= etfAmount, "Not enough ETF tokens");

        balanceOf[msg.sender] -= etfAmount;
        totalSupply -= etfAmount;

        uint256 half = etfAmount / 2;

        require(wbtc.transfer(msg.sender, half), "WBTC transfer failed");
        require(sGold.transfer(msg.sender, half), "sGOLD transfer failed");

        emit Redeemed(msg.sender, etfAmount);
    }
}
