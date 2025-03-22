// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BugBountyProgram {
    address public owner;
    uint256 public bountyReward;
    bool public bountyActive;
    address public winner;
    bool public rewardClaimed;

    event BountyCreated(uint256 reward);
    event BugSubmitted(address indexed submitter, string description);
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

    /// @notice Owner creates a bug bounty by depositing Ether into the contract.
    /// @dev The bounty reward is set to the amount of Ether sent.
    function createBounty() external payable onlyOwner {
        require(msg.value > 0, "Must send some Ether");
        bountyReward = msg.value;
        bountyActive = true;
        emit BountyCreated(bountyReward);
    }

    /// @notice Allows any participant to submit a bug report.
    /// @param description A description of the bug or vulnerability found.
    function submitBug(string calldata description) external bountyIsActive {
        emit BugSubmitted(msg.sender, description);
    }

    /// @notice Owner selects a winner for the bug bounty.
    /// @param _winner The address of the selected bug reporter.
    function selectWinner(address _winner) external onlyOwner bountyIsActive {
        require(_winner != address(0), "Invalid address");
        winner = _winner;
        bountyActive = false; // End the bounty once a winner is selected.
        emit WinnerSelected(winner);
    }

    /// @notice Allows the selected winner to claim the bounty reward.
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

    /// @notice Allows the owner to cancel the bounty and refund the funds if needed.
    function cancelBounty() external onlyOwner bountyIsActive {
        bountyActive = false;
        uint256 reward = bountyReward;
        bountyReward = 0;
        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Refund failed");
    }
}
