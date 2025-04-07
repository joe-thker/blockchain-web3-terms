// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title InitialGameOffering
/// @notice Stake base tokens during the sale to receive game tokens post-sale.
contract InitialGameOffering is Ownable {
    IERC20 public baseToken;     // e.g., USDC or platform token
    IERC20 public gameToken;     // token to be distributed
    uint256 public startTime;
    uint256 public endTime;
    uint256 public gameTokenSupply;

    uint256 public totalStaked;
    mapping(address => uint256) public userStake;
    mapping(address => bool) public hasClaimed;

    event Deposited(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 gameTokens);
    event TokensRecovered(address to, uint256 amount);

    constructor(
        address _baseToken,
        address _gameToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _gameTokenSupply
    ) Ownable(msg.sender) {
        require(_startTime < _endTime, "Invalid time frame");
        baseToken = IERC20(_baseToken);
        gameToken = IERC20(_gameToken);
        startTime = _startTime;
        endTime = _endTime;
        gameTokenSupply = _gameTokenSupply;
    }

    function deposit(uint256 amount) external {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "IGO not active");
        require(amount > 0, "Amount must be greater than zero");

        baseToken.transferFrom(msg.sender, address(this), amount);
        userStake[msg.sender] += amount;
        totalStaked += amount;

        emit Deposited(msg.sender, amount);
    }

    function claim() external {
        require(block.timestamp > endTime, "IGO still active");
        require(!hasClaimed[msg.sender], "Already claimed");
        require(userStake[msg.sender] > 0, "No stake");

        uint256 stakeAmount = userStake[msg.sender];
        uint256 reward = (stakeAmount * gameTokenSupply) / totalStaked;

        hasClaimed[msg.sender] = true;
        gameToken.transfer(msg.sender, reward);

        emit Claimed(msg.sender, reward);
    }

    /// @notice Owner can recover unclaimed game tokens
    function recoverGameTokens(address to) external onlyOwner {
        uint256 balance = gameToken.balanceOf(address(this));
        gameToken.transfer(to, balance);
        emit TokensRecovered(to, balance);
    }

    /// @notice Owner can recover unused base tokens
    function recoverBaseTokens(address to) external onlyOwner {
        uint256 balance = baseToken.balanceOf(address(this));
        baseToken.transfer(to, balance);
        emit TokensRecovered(to, balance);
    }
}
