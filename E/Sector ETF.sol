// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ Define the IERC20 interface (if not using OpenZeppelin)
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SectorETF {
    IERC20 public uni;
    IERC20 public aave;
    IERC20 public crv;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    event Minted(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);

    constructor(address _uni, address _aave, address _crv) {
        uni = IERC20(_uni);
        aave = IERC20(_aave);
        crv = IERC20(_crv);
    }

    function mint(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");

        require(uni.transferFrom(msg.sender, address(this), amount), "UNI transfer failed");
        require(aave.transferFrom(msg.sender, address(this), amount), "AAVE transfer failed");
        require(crv.transferFrom(msg.sender, address(this), amount), "CRV transfer failed");

        uint256 totalMinted = amount * 3;
        balanceOf[msg.sender] += totalMinted;
        totalSupply += totalMinted;

        emit Minted(msg.sender, totalMinted);
    }

    function redeem(uint256 etfAmount) external {
        require(balanceOf[msg.sender] >= etfAmount, "Insufficient ETF tokens");
        require(etfAmount % 3 == 0, "Must redeem in multiples of 3");

        uint256 perToken = etfAmount / 3;

        balanceOf[msg.sender] -= etfAmount;
        totalSupply -= etfAmount;

        require(uni.transfer(msg.sender, perToken), "UNI transfer failed");
        require(aave.transfer(msg.sender, perToken), "AAVE transfer failed");
        require(crv.transfer(msg.sender, perToken), "CRV transfer failed");

        emit Redeemed(msg.sender, etfAmount);
    }
}
