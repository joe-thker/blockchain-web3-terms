// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ Add the missing IERC20 interface
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BondETF {
    IERC20 public aUSDC; // Aave interest-bearing USDC
    IERC20 public stETH; // Lido staked ETH

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    event Minted(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);

    constructor(address _aUSDC, address _stETH) {
        aUSDC = IERC20(_aUSDC);
        stETH = IERC20(_stETH);
    }

    function mint(uint256 aUSDCAmount, uint256 stETHAmount) external {
        require(aUSDCAmount == stETHAmount, "Must deposit equal value");

        require(aUSDC.transferFrom(msg.sender, address(this), aUSDCAmount), "aUSDC failed");
        require(stETH.transferFrom(msg.sender, address(this), stETHAmount), "stETH failed");

        uint256 minted = aUSDCAmount + stETHAmount;
        balanceOf[msg.sender] += minted;
        totalSupply += minted;

        emit Minted(msg.sender, minted);
    }

    function redeem(uint256 etfAmount) external {
        require(balanceOf[msg.sender] >= etfAmount, "Insufficient balance");

        balanceOf[msg.sender] -= etfAmount;
        totalSupply -= etfAmount;

        uint256 half = etfAmount / 2;

        require(aUSDC.transfer(msg.sender, half), "aUSDC transfer failed");
        require(stETH.transfer(msg.sender, half), "stETH transfer failed");

        emit Redeemed(msg.sender, etfAmount);
    }
}
