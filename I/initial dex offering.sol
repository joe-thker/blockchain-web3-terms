// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title InitialDEXOffering
/// @notice This contract implements an Initial DEX Offering (IDO) where users can deposit ETH during a sale period
///         and then claim tokens at a fixed rate once the sale has ended.
contract InitialDEXOffering is Ownable {
    // The token being offered
    IERC20 public token;

    // Sale period
    uint256 public startTime;
    uint256 public endTime;

    // Rate: Number of tokens per 1 ETH contributed
    uint256 public rate;

    // Total ETH contributions (in wei)
    uint256 public totalContributions;

    // Mapping to store individual contributions
    mapping(address => uint256) public contributions;

    // Indicates if tokens have been distributed (optional, for sale finalization)
    bool public finalized;

    event Deposited(address indexed user, uint256 amount);
    event TokensClaimed(address indexed user, uint256 tokenAmount);
    event SaleFinalized(uint256 totalContributions);
    event FundsWithdrawn(uint256 amount);

    /// @param _token Address of the ERC20 token being offered.
    /// @param _startTime Unix timestamp when the sale starts.
    /// @param _endTime Unix timestamp when the sale ends.
    /// @param _rate Number of tokens given per 1 ETH.
    constructor(
        IERC20 _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate
    ) Ownable(msg.sender) {
        require(_startTime < _endTime, "Start time must be before end time");
        token = _token;
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
    }

    /// @notice Deposit ETH during the sale period.
    function deposit() external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Sale is not active");
        require(msg.value > 0, "No ETH sent");
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice After the sale, contributors can claim their tokens based on the rate.
    function claimTokens() external {
        require(block.timestamp > endTime, "Sale is not over");
        uint256 contributed = contributions[msg.sender];
        require(contributed > 0, "No contribution found");

        uint256 tokenAmount = contributed * rate;
        contributions[msg.sender] = 0;
        token.transfer(msg.sender, tokenAmount);
        emit TokensClaimed(msg.sender, tokenAmount);
    }

    /// @notice Finalize the sale (optional) and lock further contributions.
    function finalizeSale() external onlyOwner {
        require(block.timestamp > endTime, "Sale is not over yet");
        finalized = true;
        emit SaleFinalized(totalContributions);
    }

    /// @notice Withdraw the collected ETH funds after the sale is over.
    function withdrawFunds() external onlyOwner {
        require(block.timestamp > endTime, "Sale is not over yet");
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit FundsWithdrawn(balance);
    }
}
