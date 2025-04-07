// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title InitialFarmOffering
/// @notice Users stake LP tokens to earn project tokens during a fixed offering period.
contract InitialFarmOffering is Ownable {
    IERC20 public lpToken;
    IERC20 public offeringToken;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public offeringAmount;
    uint256 public totalStaked;
    bool public claimed;

    mapping(address => uint256) public userStake;
    mapping(address => bool) public hasClaimed;

    event Deposited(address indexed user, uint256 amount);
    event TokensClaimed(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(
        address _lpToken,
        address _offeringToken,
        uint256 _offeringAmount,
        uint256 _startTime,
        uint256 _endTime
    ) Ownable(msg.sender) {
        require(_startTime < _endTime, "Invalid time frame");
        lpToken = IERC20(_lpToken);
        offeringToken = IERC20(_offeringToken);
        offeringAmount = _offeringAmount;
        startTime = _startTime;
        endTime = _endTime;
    }

    function deposit(uint256 amount) external {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Not active");
        require(amount > 0, "Zero amount");
        lpToken.transferFrom(msg.sender, address(this), amount);
        userStake[msg.sender] += amount;
        totalStaked += amount;
        emit Deposited(msg.sender, amount);
    }

    function claim() external {
        require(block.timestamp > endTime, "Too early");
        require(!hasClaimed[msg.sender], "Already claimed");
        uint256 userAmount = userStake[msg.sender];
        require(userAmount > 0, "No stake");

        uint256 reward = (userAmount * offeringAmount) / totalStaked;
        hasClaimed[msg.sender] = true;
        offeringToken.transfer(msg.sender, reward);
        emit TokensClaimed(msg.sender, reward);
    }

    function emergencyWithdrawLP() external {
        require(block.timestamp > endTime, "Not allowed yet");
        uint256 amount = userStake[msg.sender];
        require(amount > 0, "No stake");
        userStake[msg.sender] = 0;
        lpToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawUnclaimedOffering(address to) external onlyOwner {
        require(block.timestamp > endTime, "Too early");
        uint256 balance = offeringToken.balanceOf(address(this));
        offeringToken.transfer(to, balance);
    }

    function recoverExcessLP(address to) external onlyOwner {
        uint256 unclaimed = lpToken.balanceOf(address(this));
        lpToken.transfer(to, unclaimed);
    }
}
