// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title InitialTokenOffering
/// @notice A basic ETH-based token sale with post-sale claiming.
contract InitialTokenOffering is Ownable {
    IERC20 public token;
    uint256 public tokenPrice; // Tokens per 1 ETH (e.g., 1000 means 1 ETH = 1000 tokens)

    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalRaised;

    mapping(address => uint256) public contributions;
    mapping(address => bool) public claimed;

    event Contributed(address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event Claimed(address indexed user, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    constructor(
        address _token,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime
    ) Ownable(msg.sender) {
        require(_startTime < _endTime, "Invalid times");
        token = IERC20(_token);
        tokenPrice = _price;
        startTime = _startTime;
        endTime = _endTime;
    }

    /// @notice Users contribute ETH during the sale period
    function contribute() external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "ITO not active");
        require(msg.value > 0, "No ETH sent");

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit Contributed(msg.sender, msg.value, msg.value * tokenPrice);
    }

    /// @notice Users claim tokens after the sale ends
    function claimTokens() external {
        require(block.timestamp > endTime, "Claim not open yet");
        require(!claimed[msg.sender], "Already claimed");

        uint256 ethContributed = contributions[msg.sender];
        require(ethContributed > 0, "No contribution");

        uint256 tokenAmount = ethContributed * tokenPrice;
        claimed[msg.sender] = true;

        token.transfer(msg.sender, tokenAmount);
        emit Claimed(msg.sender, tokenAmount);
    }

    /// @notice Owner withdraws collected ETH after sale ends
    function withdrawETH(address to) external onlyOwner {
        require(block.timestamp > endTime, "Sale not ended");
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
        emit Withdrawn(to, balance);
    }

    /// @notice Recover leftover tokens (unclaimed or unused)
    function withdrawRemainingTokens(address to) external onlyOwner {
        uint256 remaining = token.balanceOf(address(this));
        token.transfer(to, remaining);
    }
}
