// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockRewardSimulator
/// @notice This contract simulates a block reward mechanism by awarding a fixed reward
/// to an address each time they "produce" a block via the produceBlock() function.
/// Users can later claim their accumulated rewards.
contract BlockRewardSimulator {
    address public owner;
    uint256 public rewardPerBlock; // Reward amount per block (in wei or token units)
    
    // Mapping to track accumulated rewards for each producer.
    mapping(address => uint256) public rewards;
    
    // Events for block production and reward claiming.
    event BlockProduced(address indexed producer, uint256 reward);
    event RewardClaimed(address indexed producer, uint256 reward);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }
    
    /// @notice Constructor sets the contract owner and the fixed reward per block.
    /// @param _rewardPerBlock The reward amount given each time produceBlock() is called.
    constructor(uint256 _rewardPerBlock) {
        owner = msg.sender;
        rewardPerBlock = _rewardPerBlock;
    }
    
    /// @notice Simulates block production. A producer calls this function to "produce" a block,
    /// and their reward balance increases by rewardPerBlock.
    function produceBlock() public {
        rewards[msg.sender] += rewardPerBlock;
        emit BlockProduced(msg.sender, rewardPerBlock);
    }
    
    /// @notice Allows a producer to claim their accumulated rewards.
    function claimReward() public {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No reward to claim");
        rewards[msg.sender] = 0;
        // Transfer reward to the producer.
        // For this simulation, we assume the contract holds Ether to pay rewards.
        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Reward transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }
    
    /// @notice Allows the contract to receive Ether so that it can pay out rewards.
    receive() external payable {}
}
