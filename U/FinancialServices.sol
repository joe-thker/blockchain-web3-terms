// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FinancialServicesLending - Basic DeFi lending vault with collateralized borrowing

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IPriceOracle {
    function getETHPriceUSD() external view returns (uint256); // price in 1e8
}

contract FinancialServicesLending {
    IERC20 public stablecoin; // e.g., USDC, DAI
    IPriceOracle public oracle;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public debt;

    uint256 public constant COLLATERAL_RATIO = 150; // 150% overcollateralized
    uint256 public constant PRECISION = 1e8;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 ethAmount);
    event Repaid(address indexed user, uint256 amount);

    constructor(address _stablecoin, address _oracle) {
        stablecoin = IERC20(_stablecoin);
        oracle = IPriceOracle(_oracle);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Nothing to deposit");
        stablecoin.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    function borrow(uint256 ethAmount) external {
        uint256 price = oracle.getETHPriceUSD(); // e.g., 2000 * 1e8
        uint256 requiredUSD = (ethAmount * price * COLLATERAL_RATIO) / (100 * PRECISION);
        require(deposits[msg.sender] >= requiredUSD, "Insufficient collateral");

        debt[msg.sender] += ethAmount;
        payable(msg.sender).transfer(ethAmount);
        emit Borrowed(msg.sender, ethAmount);
    }

    function repay() external payable {
        require(debt[msg.sender] >= msg.value, "Repay exceeds debt");
        debt[msg.sender] -= msg.value;
        emit Repaid(msg.sender, msg.value);
    }

    function liquidate(address user) external {
        uint256 price = oracle.getETHPriceUSD();
        uint256 requiredUSD = (debt[user] * price * COLLATERAL_RATIO) / (100 * PRECISION);
        require(deposits[user] < requiredUSD, "Healthy position");

        // Seize collateral
        deposits[user] = 0;
        debt[user] = 0;
    }

    receive() external payable {}
}
