// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract IndexETF {
    IERC20 public dai;
    IERC20 public usdc;
    IERC20 public weth;

    string public name = "Index ETF Token";
    string public symbol = "iETF";
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Minted(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);

    constructor(address _dai, address _usdc, address _weth) {
        dai = IERC20(_dai);
        usdc = IERC20(_usdc);
        weth = IERC20(_weth);
    }

    function mint(uint256 daiAmount, uint256 usdcAmount, uint256 wethAmount) external {
        require(daiAmount == usdcAmount && usdcAmount == wethAmount, "Must be equal ratio");

        dai.transferFrom(msg.sender, address(this), daiAmount);
        usdc.transferFrom(msg.sender, address(this), usdcAmount);
        weth.transferFrom(msg.sender, address(this), wethAmount);

        uint256 minted = daiAmount + usdcAmount + wethAmount;
        balanceOf[msg.sender] += minted;
        totalSupply += minted;
        emit Minted(msg.sender, minted);
    }

    function redeem(uint256 etfAmount) external {
        require(balanceOf[msg.sender] >= etfAmount, "Insufficient balance");
        balanceOf[msg.sender] -= etfAmount;
        totalSupply -= etfAmount;

        uint256 share = etfAmount / 3;
        dai.transfer(msg.sender, share);
        usdc.transfer(msg.sender, share);
        weth.transfer(msg.sender, share);
        emit Redeemed(msg.sender, etfAmount);
    }
}
