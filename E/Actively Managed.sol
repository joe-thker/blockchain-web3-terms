// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ Add the missing IERC20 interface
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ActivelyManagedETF {
    address public manager;
    IERC20[] public portfolio;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    event TokenAdded(address token);
    event Minted(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);
    event ManagerChanged(address oldManager, address newManager);

    modifier onlyManager() {
        require(msg.sender == manager, "Not manager");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

    // Add tokens to the ETF (by manager)
    function addToken(address token) external onlyManager {
        require(token != address(0), "Invalid token");
        portfolio.push(IERC20(token));
        emit TokenAdded(token);
    }

    // Mint ETF by depositing equal amounts of all portfolio tokens
    function mint(uint256 amount) external {
        require(portfolio.length > 0, "Portfolio is empty");
        for (uint256 i = 0; i < portfolio.length; i++) {
            require(
                portfolio[i].transferFrom(msg.sender, address(this), amount),
                "Transfer failed"
            );
        }

        uint256 minted = amount * portfolio.length;
        balanceOf[msg.sender] += minted;
        totalSupply += minted;
        emit Minted(msg.sender, minted);
    }

    // Redeem ETF and withdraw equal amount of each token
    function redeem(uint256 etfAmount) external {
        require(balanceOf[msg.sender] >= etfAmount, "Insufficient ETF tokens");
        require(etfAmount % portfolio.length == 0, "Invalid ETF amount");

        uint256 perToken = etfAmount / portfolio.length;

        balanceOf[msg.sender] -= etfAmount;
        totalSupply -= etfAmount;

        for (uint256 i = 0; i < portfolio.length; i++) {
            require(
                portfolio[i].transfer(msg.sender, perToken),
                "Transfer failed"
            );
        }

        emit Redeemed(msg.sender, etfAmount);
    }

    // Change manager
    function changeManager(address newManager) external onlyManager {
        require(newManager != address(0), "Invalid address");
        emit ManagerChanged(manager, newManager);
        manager = newManager;
    }

    // Get number of tokens in portfolio
    function getPortfolioLength() external view returns (uint256) {
        return portfolio.length;
    }
}
