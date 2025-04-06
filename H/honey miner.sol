// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HoneyMinerSim {
    address public owner;
    mapping(address => uint256) public hashPoints;
    mapping(address => bool) public registered;

    uint256 public totalPoints;
    uint256 public rewardPool; // in wei (ETH)
    bool public claimEnabled;

    event Registered(address miner);
    event Contributed(address miner, uint256 points);
    event RewardClaimed(address miner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() payable {
        owner = msg.sender;
        rewardPool = msg.value;
    }

    function register() external {
        require(!registered[msg.sender], "Already registered");
        registered[msg.sender] = true;
        emit Registered(msg.sender);
    }

    function contributeHash(uint256 points) external {
        require(registered[msg.sender], "Not registered");
        hashPoints[msg.sender] += points;
        totalPoints += points;
        emit Contributed(msg.sender, points);
    }

    function enableClaims() external onlyOwner {
        claimEnabled = true;
    }

    function claimReward() external {
        require(claimEnabled, "Claiming not yet open");
        require(hashPoints[msg.sender] > 0, "No points");

        uint256 share = (rewardPool * hashPoints[msg.sender]) / totalPoints;
        hashPoints[msg.sender] = 0;

        payable(msg.sender).transfer(share);
        emit RewardClaimed(msg.sender, share);
    }
}
