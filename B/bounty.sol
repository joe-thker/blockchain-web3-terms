// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BountyProgram {
    address public owner;
    uint256 public bountyReward;
    bool public bountyActive;
    address public winner;
    bool public rewardClaimed;

    event BountyCreated(uint256 reward);
    event SubmissionReceived(address indexed submitter, string submission);
    event WinnerSelected(address indexed winner);
    event RewardClaimed(address indexed winner, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }
    
    modifier bountyIsActive() {
        require(bountyActive, "Bounty is not active");
        _;
    }
    
    constructor() payable {
        owner = msg.sender;
        bountyActive = false;
        rewardClaimed = false;
    }
    
    /// @notice Owner creates a bounty by depositing Ether.
    /// @dev The bounty reward is set to the amount of Ether sent.
    function createBounty() external payable onlyOwner {
        require(msg.value > 0, "Must send some Ether");
        bountyReward = msg.value;
        bountyActive = true;
        emit BountyCreated(bountyReward);
    }
    
    /// @notice Allows anyone to submit a proposal.
    /// @param submission A string describing the proposal or solution.
    function submitProposal(string calldata submission) external bountyIsActive {
        emit SubmissionReceived(msg.sender, submission);
    }
    
    /// @notice Owner selects a winner for the bounty.
    /// @param _winner The address of the selected winner.
    function selectWinner(address _winner) external onlyOwner bountyIsActive {
        require(_winner != address(0), "Invalid address");
        winner = _winner;
        bountyActive = false; // End the bounty
        emit WinnerSelected(winner);
    }
    
    /// @notice Allows the winner to claim the bounty reward.
    function claimReward() external {
        require(msg.sender == winner, "Only winner can claim reward");
        require(!rewardClaimed, "Reward already claimed");
        rewardClaimed = true;
        uint256 reward = bountyReward;
        bountyReward = 0;
        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Reward transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }
    
    /// @notice Allows the owner to cancel the bounty and refund the bounty reward.
    function cancelBounty() external onlyOwner bountyIsActive {
        bountyActive = false;
        uint256 reward = bountyReward;
        bountyReward = 0;
        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Refund failed");
    }
}
