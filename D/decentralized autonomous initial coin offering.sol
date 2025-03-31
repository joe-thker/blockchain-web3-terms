// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title DAICO - Decentralized Autonomous Initial Coin Offering
contract DAICO is Ownable, ReentrancyGuard, ERC20 {
    uint256 public rate;  // Tokens per ETH
    uint256 public fundingGoal;
    uint256 public fundsRaised;
    bool public isFundingActive;

    // Mapping to track contributions
    mapping(address => uint256) public contributions;

    // Voting mechanism
    mapping(address => bool) public hasVoted;
    uint256 public totalVotes;
    uint256 public requiredVotesPercentage; // scaled by 10000 (50% = 5000)

    // Events
    event Contribution(address indexed investor, uint256 amount, uint256 tokens);
    event FundsWithdrawn(address indexed team, uint256 amount);
    event VotingStarted();
    event Voted(address indexed voter);
    event FundingEnded();

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _rate,
        uint256 _fundingGoal,
        uint256 _requiredVotesPercentage
    )
        ERC20(_name, _symbol)
        Ownable(msg.sender)
    {
        require(_rate > 0, "Rate must be greater than 0");
        require(_fundingGoal > 0, "Goal must be greater than 0");
        require(_requiredVotesPercentage <= 10000, "Votes percent max 100%");

        rate = _rate;
        fundingGoal = _fundingGoal;
        requiredVotesPercentage = _requiredVotesPercentage;
        isFundingActive = true;
    }

    /// @notice Investors contribute ETH to the DAICO
    function contribute() external payable nonReentrant {
        require(isFundingActive, "Funding is closed");
        require(msg.value > 0, "Contribution must be greater than 0");

        uint256 tokensToMint = msg.value * rate;
        contributions[msg.sender] += msg.value;
        fundsRaised += msg.value;

        _mint(msg.sender, tokensToMint);
        emit Contribution(msg.sender, msg.value, tokensToMint);

        if (fundsRaised >= fundingGoal) {
            isFundingActive = false;
            emit FundingEnded();
        }
    }

    /// @notice Investors initiate a vote to allow team withdrawal
    function voteForFundRelease() external nonReentrant {
        require(contributions[msg.sender] > 0, "Must be an investor");
        require(!hasVoted[msg.sender], "Already voted");

        hasVoted[msg.sender] = true;
        totalVotes += contributions[msg.sender];

        emit Voted(msg.sender);
    }

    /// @notice Owner (project team) withdraws funds after receiving enough votes
    function withdrawFunds() external onlyOwner nonReentrant {
        require(!isFundingActive, "Funding still active");
        uint256 requiredVotes = (fundsRaised * requiredVotesPercentage) / 10000;
        require(totalVotes >= requiredVotes, "Not enough votes");

        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");

        (bool success,) = payable(owner()).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(owner(), amount);
    }

    /// @notice Check if sufficient votes received
    function hasEnoughVotes() public view returns (bool) {
        uint256 requiredVotes = (fundsRaised * requiredVotesPercentage) / 10000;
        return totalVotes >= requiredVotes;
    }

    /// @notice Ends funding period manually (only by owner)
    function endFundingManually() external onlyOwner {
        require(isFundingActive, "Funding already ended");
        isFundingActive = false;
        emit FundingEnded();
    }

    /// @notice Retrieve contract's ETH balance
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
