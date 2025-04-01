// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DelegatedProofOfStake
/// @notice This contract implements a simplified Delegated Proof-of-Stake system.
/// Token holders (delegators) deposit a staking token and delegate their stake to a validator.
/// Validators accumulate votes (total staked tokens) based on delegations.
/// Delegators can update their delegation or withdraw their stake.
contract DelegatedProofOfStake is Ownable, ReentrancyGuard {
    // The ERC20 token used for staking.
    IERC20 public stakingToken;

    // Minimum stake amount required.
    uint256 public minStake;

    // Mapping from delegator address to the amount staked.
    mapping(address => uint256) public delegatorStakes;

    // Mapping from delegator address to the validator they delegate to.
    mapping(address => address) public delegations;

    // Mapping from validator address to total delegated stake (voting power).
    mapping(address => uint256) public validatorVotes;

    // --- Events ---
    event StakeDeposited(address indexed delegator, uint256 amount);
    event Delegated(address indexed delegator, address indexed validator, uint256 amount);
    event DelegationUpdated(address indexed delegator, address indexed oldValidator, address indexed newValidator, uint256 amount);
    event StakeWithdrawn(address indexed delegator, uint256 amount);
    event Undelegated(address indexed delegator, address indexed validator, uint256 amount);

    /// @notice Constructor sets the staking token and minimum stake.
    /// @param _stakingToken The ERC20 token used for staking.
    /// @param _minStake The minimum stake amount.
    constructor(IERC20 _stakingToken, uint256 _minStake) Ownable(msg.sender) {
        require(address(_stakingToken) != address(0), "Invalid token address");
        require(_minStake > 0, "Minimum stake must be > 0");
        stakingToken = _stakingToken;
        minStake = _minStake;
    }

    /// @notice Deposits staking tokens and delegates the stake to a validator.
    /// @param amount The amount of tokens to deposit.
    /// @param validator The address of the validator to delegate to.
    function depositAndDelegate(uint256 amount, address validator) external nonReentrant {
        require(amount >= minStake, "Amount less than minimum stake");
        require(validator != address(0), "Invalid validator address");

        // Transfer staking tokens from the delegator to this contract.
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Update delegator's stake.
        delegatorStakes[msg.sender] += amount;
        emit StakeDeposited(msg.sender, amount);

        // If the delegator hasn't delegated yet, set the delegation.
        if (delegations[msg.sender] == address(0)) {
            delegations[msg.sender] = validator;
            validatorVotes[validator] += amount;
            emit Delegated(msg.sender, validator, amount);
        } else {
            // If already delegated to the same validator, simply add the stake.
            // If already delegated to a different validator, revert (or use updateDelegation).
            require(delegations[msg.sender] == validator, "Already delegated to a different validator");
            validatorVotes[validator] += amount;
            emit Delegated(msg.sender, validator, amount);
        }
    }

    /// @notice Updates the delegation for the sender from one validator to another.
    /// @param newValidator The new validator address.
    function updateDelegation(address newValidator) external nonReentrant {
        require(newValidator != address(0), "Invalid validator address");
        address currentValidator = delegations[msg.sender];
        require(currentValidator != address(0), "No existing delegation");
        require(currentValidator != newValidator, "Already delegated to this validator");

        uint256 stakeAmount = delegatorStakes[msg.sender];
        require(stakeAmount > 0, "No stake deposited");

        // Remove stake from current validator's vote.
        validatorVotes[currentValidator] -= stakeAmount;
        // Add stake to new validator's vote.
        validatorVotes[newValidator] += stakeAmount;
        // Update delegation.
        delegations[msg.sender] = newValidator;

        emit DelegationUpdated(msg.sender, currentValidator, newValidator, stakeAmount);
    }

    /// @notice Withdraws a specified amount of staked tokens and updates the delegation accordingly.
    /// @param amount The amount to withdraw.
    function withdrawStake(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdrawal amount must be > 0");
        require(delegatorStakes[msg.sender] >= amount, "Insufficient stake");

        address validator = delegations[msg.sender];
        require(validator != address(0), "No delegation found");

        // Deduct the withdrawn amount from the delegator's stake and validator's votes.
        delegatorStakes[msg.sender] -= amount;
        validatorVotes[validator] -= amount;

        // Transfer tokens back to the delegator.
        require(stakingToken.transfer(msg.sender, amount), "Token transfer failed");
        emit StakeWithdrawn(msg.sender, amount);

        // If all stake is withdrawn, clear the delegation.
        if (delegatorStakes[msg.sender] == 0) {
            emit Undelegated(msg.sender, validator, amount);
            delegations[msg.sender] = address(0);
        }
    }

    /// @notice Returns the validator currently delegated by the given delegator.
    /// @param delegator The delegator's address.
    /// @return The validator's address.
    function getDelegation(address delegator) external view returns (address) {
        return delegations[delegator];
    }

    /// @notice Returns the total delegated stake (voting power) for a validator.
    /// @param validator The validator's address.
    /// @return The total delegated stake.
    function getValidatorVotes(address validator) external view returns (uint256) {
        return validatorVotes[validator];
    }
}
