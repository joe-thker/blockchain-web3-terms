// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Crowdfunding
/// @notice This contract allows users to create crowdfunding campaigns, contribute funds, and claim refunds if the funding goal is not met.
contract Crowdfunding is ReentrancyGuard {
    
    // Structure representing a crowdfunding campaign.
    struct Campaign {
        address payable creator;   // Campaign creator who can withdraw funds if the goal is reached.
        string title;              // Title of the campaign.
        string description;        // Campaign description.
        uint256 goal;              // Funding goal (in wei).
        uint256 deadline;          // Campaign deadline as a Unix timestamp.
        uint256 totalRaised;       // Total funds raised.
        bool withdrawn;            // Whether the creator has withdrawn the funds.
    }
    
    uint256 public nextCampaignId;
    mapping(uint256 => Campaign) public campaigns;
    
    // Mapping: campaignId => (contributor => amount contributed)
    mapping(uint256 => mapping(address => uint256)) public contributions;
    
    // Events for logging important actions.
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        string title,
        uint256 goal,
        uint256 deadline
    );
    event ContributionReceived(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    event FundsWithdrawn(uint256 indexed campaignId, uint256 amount);
    event RefundIssued(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    
    /// @notice Creates a new crowdfunding campaign.
    /// @param title The title of the campaign.
    /// @param description A description of the campaign.
    /// @param goal The funding goal in wei.
    /// @param duration The duration of the campaign in seconds from now.
    /// @return campaignId The ID assigned to the new campaign.
    function createCampaign(
        string calldata title,
        string calldata description,
        uint256 goal,
        uint256 duration
    ) external returns (uint256 campaignId) {
        require(goal > 0, "Goal must be > 0");
        require(duration > 0, "Duration must be > 0");
        
        uint256 deadline = block.timestamp + duration;
        campaignId = nextCampaignId;
        campaigns[campaignId] = Campaign({
            creator: payable(msg.sender),
            title: title,
            description: description,
            goal: goal,
            deadline: deadline,
            totalRaised: 0,
            withdrawn: false
        });
        nextCampaignId++;
        
        emit CampaignCreated(campaignId, msg.sender, title, goal, deadline);
    }
    
    /// @notice Contribute Ether to a specific campaign.
    /// @param campaignId The ID of the campaign to contribute to.
    function contribute(uint256 campaignId) external payable nonReentrant {
        Campaign storage camp = campaigns[campaignId];
        require(block.timestamp < camp.deadline, "Campaign has ended");
        require(msg.value > 0, "Contribution must be > 0");
        
        camp.totalRaised += msg.value;
        contributions[campaignId][msg.sender] += msg.value;
        
        emit ContributionReceived(campaignId, msg.sender, msg.value);
    }
    
    /// @notice Allows the campaign creator to withdraw funds if the campaign was successful.
    /// @param campaignId The ID of the campaign.
    function withdrawFunds(uint256 campaignId) external nonReentrant {
        Campaign storage camp = campaigns[campaignId];
        require(msg.sender == camp.creator, "Only creator can withdraw");
        require(block.timestamp >= camp.deadline, "Campaign not ended");
        require(camp.totalRaised >= camp.goal, "Funding goal not reached");
        require(!camp.withdrawn, "Funds already withdrawn");
        
        camp.withdrawn = true;
        uint256 amount = camp.totalRaised;
        (bool success, ) = camp.creator.call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit FundsWithdrawn(campaignId, amount);
    }
    
    /// @notice Allows contributors to claim refunds if the campaign was unsuccessful.
    /// @param campaignId The ID of the campaign.
    function refund(uint256 campaignId) external nonReentrant {
        Campaign storage camp = campaigns[campaignId];
        require(block.timestamp >= camp.deadline, "Campaign not ended");
        require(camp.totalRaised < camp.goal, "Campaign reached goal, no refunds");
        
        uint256 contributed = contributions[campaignId][msg.sender];
        require(contributed > 0, "No contributions to refund");
        
        contributions[campaignId][msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: contributed}("");
        require(success, "Refund transfer failed");
        
        emit RefundIssued(campaignId, msg.sender, contributed);
    }
}
