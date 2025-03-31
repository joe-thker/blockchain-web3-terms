// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CrowdLoan
/// @notice This contract implements a dynamic and secure crowd loan mechanism.
/// Users contribute Ether during a campaign period. If the funding goal is reached by the deadline,
/// the owner can declare the candidate as the winner and lock the funds until a specified unlock time.
/// Otherwise, contributors can claim a refund.
contract CrowdLoan is Ownable, ReentrancyGuard {
    // Funding parameters
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalContributed;
    
    // Campaign outcome and fund locking parameters
    bool public candidateWon;
    bool public fundsLocked;
    uint256 public unlockTime;
    bool public campaignClosed;

    // Contributions per address
    mapping(address => uint256) public contributions;

    // Events for tracking campaign lifecycle
    event ContributionReceived(address indexed contributor, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);
    event CandidateDeclaredWinner(uint256 unlockTime);
    event CampaignClosed();

    /// @notice Constructor sets the funding goal and campaign duration.
    /// @param _fundingGoal The target amount to raise (in wei).
    /// @param _duration The duration of the campaign in seconds.
    constructor(uint256 _fundingGoal, uint256 _duration) {
        require(_fundingGoal > 0, "Goal must be > 0");
        require(_duration > 0, "Duration must be > 0");
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + _duration;
    }

    /// @notice Allows users to contribute funds during the campaign period.
    function contribute() external payable nonReentrant {
        require(block.timestamp < deadline, "Campaign has ended");
        require(msg.value > 0, "Contribution must be > 0");
        
        contributions[msg.sender] += msg.value;
        totalContributed += msg.value;
        
        emit ContributionReceived(msg.sender, msg.value);
    }

    /// @notice Declares that the candidate has won and locks the funds.
    /// @param _unlockTime The Unix timestamp after which funds can be withdrawn by the candidate.
    /// Only the owner can call this function.
    function declareWinner(uint256 _unlockTime) external onlyOwner {
        require(block.timestamp >= deadline, "Campaign not ended");
        require(totalContributed >= fundingGoal, "Funding goal not reached");
        require(!campaignClosed, "Campaign already closed");
        candidateWon = true;
        fundsLocked = true;
        unlockTime = _unlockTime;
        campaignClosed = true;
        
        emit CandidateDeclaredWinner(_unlockTime);
        emit CampaignClosed();
    }

    /// @notice Closes the campaign if the funding goal was not reached.
    /// Only the owner can close the campaign in this case.
    function closeCampaign() external onlyOwner {
        require(block.timestamp >= deadline, "Campaign not ended");
        require(totalContributed < fundingGoal, "Funding goal reached");
        require(!campaignClosed, "Campaign already closed");
        
        campaignClosed = true;
        emit CampaignClosed();
    }

    /// @notice Allows contributors to claim refunds if the campaign did not reach its funding goal.
    function claimRefund() external nonReentrant {
        require(campaignClosed, "Campaign not closed yet");
        require(!candidateWon, "Candidate won, no refunds");
        uint256 contributed = contributions[msg.sender];
        require(contributed > 0, "No contributions to refund");
        
        contributions[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: contributed}("");
        require(success, "Refund failed");
        
        emit RefundClaimed(msg.sender, contributed);
    }

    /// @notice Retrieves the current campaign status.
    /// @return goal The funding goal.
    /// @return raised The total funds raised.
    /// @return deadlineTime The campaign deadline.
    /// @return winnerDeclared Whether the candidate has been declared a winner.
    /// @return locked Whether funds are locked.
    /// @return closed Whether the campaign is closed.
    function getCampaignStatus() external view returns (
        uint256 goal,
        uint256 raised,
        uint256 deadlineTime,
        bool winnerDeclared,
        bool locked,
        bool closed
    ) {
        return (fundingGoal, totalContributed, deadline, candidateWon, fundsLocked, campaignClosed);
    }
}
