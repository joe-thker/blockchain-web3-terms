// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal ERC20 interface
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

/// @title Staked Governance Token System
contract StakedGovernance {
    IERC20 public govToken;

    mapping(address => uint256) public staked;
    mapping(address => uint256) public votingPower;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event VotePowerUpdated(address indexed user, uint256 votingPower);

    constructor(address _govToken) {
        govToken = IERC20(_govToken);
    }

    /// @notice Stake governance tokens to gain voting power
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(govToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        staked[msg.sender] += amount;
        votingPower[msg.sender] = staked[msg.sender];

        emit Staked(msg.sender, amount);
        emit VotePowerUpdated(msg.sender, votingPower[msg.sender]);
    }

    /// @notice Unstake and lose voting power
    function unstake(uint256 amount) external {
        require(staked[msg.sender] >= amount, "Insufficient stake");

        staked[msg.sender] -= amount;
        votingPower[msg.sender] = staked[msg.sender];

        require(govToken.transfer(msg.sender, amount), "Transfer failed");

        emit Unstaked(msg.sender, amount);
        emit VotePowerUpdated(msg.sender, votingPower[msg.sender]);
    }

    /// @notice Get current voting power
    function getVotingPower(address user) external view returns (uint256) {
        return votingPower[user];
    }
}
