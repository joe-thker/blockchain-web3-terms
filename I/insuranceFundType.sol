// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title 1. Simple Emergency Reserve Fund
contract EmergencyReserveFund is Ownable {
    IERC20 public token;
    uint256 public reserves;

    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
    }

    function deposit(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        reserves += amount;
    }

    function payout(address recipient, uint256 amount) external onlyOwner {
        require(amount <= reserves, "Exceeds reserve");
        reserves -= amount;
        token.transfer(recipient, amount);
    }
}

/// @title 2. Automated Liquidation Backstop Fund
contract LiquidationBackstop is Ownable {
    IERC20 public token;
    address public lendingProtocol;

    constructor(IERC20 _token, address _lendingProtocol) Ownable(msg.sender) {
        token = _token;
        lendingProtocol = _lendingProtocol;
    }

    modifier onlyProtocol() {
        require(msg.sender == lendingProtocol, "Not authorized");
        _;
    }

    function coverShortfall(address user, uint256 amount) external onlyProtocol {
        token.transfer(user, amount);
    }

    function fund(uint256 amount) external onlyOwner {
        token.transferFrom(msg.sender, address(this), amount);
    }
}

/// @title 3. DAO-Governed Insurance Fund
contract DAOInsuranceFund {
    IERC20 public token;
    address public dao;

    mapping(address => uint256) public claims;

    constructor(IERC20 _token, address _dao) {
        token = _token;
        dao = _dao;
    }

    modifier onlyDAO() {
        require(msg.sender == dao, "Not DAO");
        _;
    }

    function submitClaim(address user, uint256 amount) external onlyDAO {
        claims[user] += amount;
    }

    function payoutClaim() external {
        uint256 claim = claims[msg.sender];
        require(claim > 0, "No claim");
        claims[msg.sender] = 0;
        token.transfer(msg.sender, claim);
    }
}

/// @title 4. Yield-Based Insurance Pool
contract YieldInsuranceFund is Ownable {
    IERC20 public token;
    address public yieldSource;
    uint256 public poolBalance;

    constructor(IERC20 _token, address _yieldSource) Ownable(msg.sender) {
        token = _token;
        yieldSource = _yieldSource;
    }

    function harvest(uint256 amount) external onlyOwner {
        token.transferFrom(yieldSource, address(this), amount);
        poolBalance += amount;
    }

    function emergencyPayout(address to, uint256 amount) external onlyOwner {
        require(amount <= poolBalance, "Not enough");
        poolBalance -= amount;
        token.transfer(to, amount);
    }
}

/// @title 5. Community-Contributed Safety Fund
contract CommunitySafetyFund {
    IERC20 public token;
    mapping(address => uint256) public contributions;
    uint256 public totalContributed;

    constructor(IERC20 _token) {
        token = _token;
    }

    function contribute(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        contributions[msg.sender] += amount;
        totalContributed += amount;
    }

    function refund(address contributor, uint256 amount) external {
        require(contributions[contributor] >= amount, "Too much");
        contributions[contributor] -= amount;
        totalContributed -= amount;
        token.transfer(contributor, amount);
    }

    function payoutLoss(address to, uint256 amount) external {
        require(amount <= totalContributed, "Exceeds fund");
        totalContributed -= amount;
        token.transfer(to, amount);
    }
}
