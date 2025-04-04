// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract CryptoETF {
    address public owner;

    IERC20 public dai;
    IERC20 public usdc;

    string public name = "Crypto ETF Token";
    string public symbol = "cETF";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event Minted(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _dai, address _usdc) {
        owner = msg.sender;
        dai = IERC20(_dai);
        usdc = IERC20(_usdc);
    }

    // Mint ETF tokens by depositing equal value of DAI + USDC
    function mint(uint256 daiAmount, uint256 usdcAmount) external {
        require(daiAmount == usdcAmount, "Amounts must be equal");

        require(dai.transferFrom(msg.sender, address(this), daiAmount), "DAI transfer failed");
        require(usdc.transferFrom(msg.sender, address(this), usdcAmount), "USDC transfer failed");

        uint256 minted = daiAmount + usdcAmount;
        balanceOf[msg.sender] += minted;
        totalSupply += minted;

        emit Minted(msg.sender, minted);
    }

    // Redeem ETF tokens to get back DAI and USDC
    function redeem(uint256 etfAmount) external {
        require(balanceOf[msg.sender] >= etfAmount, "Not enough ETF tokens");

        uint256 daiShare = etfAmount / 2;
        uint256 usdcShare = etfAmount / 2;

        balanceOf[msg.sender] -= etfAmount;
        totalSupply -= etfAmount;

        require(dai.transfer(msg.sender, daiShare), "DAI transfer failed");
        require(usdc.transfer(msg.sender, usdcShare), "USDC transfer failed");

        emit Redeemed(msg.sender, etfAmount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getBackingReserves() external view returns (uint256 daiReserve, uint256 usdcReserve) {
        daiReserve = dai.balanceOf(address(this));
        usdcReserve = usdc.balanceOf(address(this));
    }
}
