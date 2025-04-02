// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Minimal interface for ERC20 tokens used for staking.
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title DiversifiedProofOfStake
/// @notice A dynamic, optimized contract letting users stake multiple ERC20 tokens (a "diversified" set) to gain voting power.
/// Each whitelisted token has a weight (basis points). A user’s total stake is sum of (token balance * weight).
/// The owner can add or remove tokens and update weights.
contract DiversifiedProofOfStake is Ownable, ReentrancyGuard {
    /// @notice Data structure for tokens allowed for staking.
    /// Each token has an address and a weight in basis points (e.g., 2000 = 20%).
    struct StakeToken {
        address token;
        uint256 weightBps;
        bool active;
    }

    // List of tokens in the diversified stake set
    StakeToken[] public stakeTokens;
    // Mapping token address => index+1 in stakeTokens array for quick lookups
    mapping(address => uint256) public stakeTokenIndexPlusOne;

    /// @notice Sum of all active token weights in basis points. Must be <= 10000 for 100%.
    uint256 public totalWeightsBps;

    /// @notice Mapping from user => (token => staked balance).
    /// Each user can stake multiple tokens. We'll track each token balance separately.
    mapping(address => mapping(address => uint256)) public userStakes;

    // --- Events ---
    event TokenAdded(address indexed token, uint256 weightBps);
    event TokenUpdated(address indexed token, uint256 newWeightBps);
    event TokenRemoved(address indexed token);

    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);

    /// @notice Constructor sets deployer as the initial owner.
    /// Using Ownable(msg.sender) to fix “no arguments for base constructor” error.
    constructor() Ownable(msg.sender) {}

    // --- Owner Functions ---

    /// @notice Adds a new token to the staking set with a certain weight in basis points.
    /// @param token The ERC20 token address to whitelist for staking.
    /// @param weightBps The weight in basis points for this token.
    function addStakeToken(address token, uint256 weightBps) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(weightBps > 0, "Weight must be > 0");
        require(stakeTokenIndexPlusOne[token] == 0, "Token already added");
        require(totalWeightsBps + weightBps <= 10000, "Total weight exceeds 100%");

        stakeTokens.push(StakeToken({
            token: token,
            weightBps: weightBps,
            active: true
        }));
        stakeTokenIndexPlusOne[token] = stakeTokens.length;
        totalWeightsBps += weightBps;

        emit TokenAdded(token, weightBps);
    }

    /// @notice Updates the weight of an existing token. Must still keep total weights <= 10000.
    /// @param token The token address to update.
    /// @param newWeightBps The new weight in basis points.
    function updateStakeToken(address token, uint256 newWeightBps) external onlyOwner {
        uint256 idxPlusOne = stakeTokenIndexPlusOne[token];
        require(idxPlusOne != 0, "Token not in set");
        uint256 index = idxPlusOne - 1;
        StakeToken storage st = stakeTokens[index];
        require(st.active, "Token is inactive");
        require(newWeightBps > 0, "Weight must be > 0");

        // adjust totalWeightsBps
        totalWeightsBps = totalWeightsBps - st.weightBps + newWeightBps;
        require(totalWeightsBps <= 10000, "Total weight exceeds 100%");
        st.weightBps = newWeightBps;

        emit TokenUpdated(token, newWeightBps);
    }

    /// @notice Removes (deactivates) a token from the set, so no new staking in it. Already staked user balances remain. 
    /// Weight is removed from totalWeightsBps.
    /// @param token The token address to remove.
    function removeStakeToken(address token) external onlyOwner {
        uint256 idxPlusOne = stakeTokenIndexPlusOne[token];
        require(idxPlusOne != 0, "Token not in set");
        uint256 index = idxPlusOne - 1;
        StakeToken storage st = stakeTokens[index];
        require(st.active, "Token already inactive");

        st.active = false;
        totalWeightsBps -= st.weightBps;
        st.weightBps = 0;
        stakeTokenIndexPlusOne[token] = 0;

        emit TokenRemoved(token);
    }

    // --- User Staking ---

    /// @notice A user stakes a certain amount of a whitelisted token. The user must have approved this contract.
    /// @param token The token to stake.
    /// @param amount The amount of tokens to stake.
    function stake(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Staked amount must be > 0");
        uint256 idxPlusOne = stakeTokenIndexPlusOne[token];
        require(idxPlusOne != 0, "Token not in set");
        StakeToken memory st = stakeTokens[idxPlusOne - 1];
        require(st.active, "Token is inactive");
        
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        userStakes[msg.sender][token] += amount;

        emit Staked(msg.sender, token, amount);
    }

    /// @notice A user unstakes (withdraws) some amount of a previously staked token.
    /// @param token The token to unstake.
    /// @param amount The amount to unstake.
    function unstake(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Unstake amount must be > 0");
        uint256 stakedBalance = userStakes[msg.sender][token];
        require(stakedBalance >= amount, "Insufficient staked balance");

        userStakes[msg.sender][token] = stakedBalance - amount;
        bool success = IERC20(token).transfer(msg.sender, amount);
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, token, amount);
    }

    // --- View Functions ---

    /// @notice Returns the total number of tokens in the stake set (including inactive).
    /// @return The length of stakeTokens array.
    function totalStakeTokens() external view returns (uint256) {
        return stakeTokens.length;
    }

    /// @notice Retrieves the stake token info by index in the stakeTokens array.
    /// @param index The index in the array.
    /// @return A StakeToken struct with token address, weightBps, and active status.
    function getStakeToken(uint256 index) external view returns (StakeToken memory) {
        require(index < stakeTokens.length, "Index out of range");
        return stakeTokens[index];
    }

    /// @notice Calculates the total stake (voting power) of a user across all staked tokens,
    /// as sum of (balance * weightBps).
    /// @param user The user address.
    /// @return totalVotingPower The sum of (balanceOf(token) * weightBps) for all active tokens.
    function getUserVotingPower(address user) external view returns (uint256 totalVotingPower) {
        for (uint256 i = 0; i < stakeTokens.length; i++) {
            StakeToken memory st = stakeTokens[i];
            if (st.active) {
                uint256 balance = userStakes[user][st.token];
                totalVotingPower += (balance * st.weightBps);
            }
        }
        // totalVotingPower is scaled by 1 basis point for the weights. 
        // If needed, you can define a normalizing factor or keep it as is for relative weighting.
    }
}
