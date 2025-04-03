// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title EffectiveProofOfStake
/// @notice This contract implements an effective proof-of-stake system where each user's effective stake
/// increases over time. The effective stake is computed as:
/// effectiveStake = stakedAmount * (1 + (elapsedTime / bonusPeriod))
/// The owner sets the staking token and the bonus period (e.g., 30 days).
contract EffectiveProofOfStake is Ownable, ReentrancyGuard {
    /// @notice The ERC20 token used for staking.
    IERC20 public stakingToken;
    /// @notice Bonus period in seconds (e.g., 30 days = 30 * 24 * 60 * 60).
    uint256 public bonusPeriod;

    /// @notice Information about a user's stake.
    struct StakeInfo {
        uint256 amount;              // Total tokens staked by the user
        uint256 weightedDepositTime; // A weighted average deposit timestamp (in seconds)
    }

    /// @notice Mapping from user address to their stake information.
    mapping(address => StakeInfo) public stakes;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event BonusPeriodUpdated(uint256 newBonusPeriod);

    /**
     * @notice Constructor sets the staking token and bonus period.
     * @param _stakingToken The ERC20 token address used for staking.
     * @param _bonusPeriod The bonus period in seconds (e.g., 30 days).
     */
    constructor(address _stakingToken, uint256 _bonusPeriod) Ownable(msg.sender) {
        require(_stakingToken != address(0), "Invalid token address");
        require(_bonusPeriod > 0, "Bonus period must be > 0");

        stakingToken = IERC20(_stakingToken);
        bonusPeriod = _bonusPeriod;
    }

    /**
     * @notice Allows a user to deposit tokens for staking.
     * The deposited tokens are recorded, and the weighted deposit time is updated.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be > 0");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        StakeInfo storage info = stakes[msg.sender];
        uint256 totalAmount = info.amount + amount;

        if (info.amount == 0) {
            // If this is the first deposit, set weighted deposit time to current block timestamp.
            info.weightedDepositTime = block.timestamp;
        } else {
            // Compute new weighted deposit time:
            // newWeightedTime = (oldWeightedTime * oldAmount + block.timestamp * newAmount) / (oldAmount + newAmount)
            info.weightedDepositTime = (info.weightedDepositTime * info.amount + block.timestamp * amount) / totalAmount;
        }
        info.amount = totalAmount;

        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Allows a user to withdraw (unstake) tokens.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) external nonReentrant {
        StakeInfo storage info = stakes[msg.sender];
        require(info.amount >= amount, "Insufficient staked balance");

        info.amount -= amount;
        if (info.amount == 0) {
            info.weightedDepositTime = 0;
        }
        require(stakingToken.transfer(msg.sender, amount), "Token transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Calculates the effective stake of a user.
     * The effective stake increases over time based on how long the tokens have been staked.
     * @param user The address of the user.
     * @return The effective stake value.
     */
    function effectiveStake(address user) external view returns (uint256) {
        StakeInfo storage info = stakes[user];
        if (info.amount == 0) {
            return 0;
        }
        uint256 elapsed = block.timestamp - info.weightedDepositTime;
        // Calculate multiplier: 1 + (elapsed / bonusPeriod)
        // We scale calculations by 1e18 for precision.
        uint256 multiplier = 1e18 + (elapsed * 1e18) / bonusPeriod;
        return (info.amount * multiplier) / 1e18;
    }

    /**
     * @notice Updates the bonus period. Only the owner can call this.
     * @param newBonusPeriod The new bonus period in seconds.
     */
    function updateBonusPeriod(uint256 newBonusPeriod) external onlyOwner {
        require(newBonusPeriod > 0, "Bonus period must be > 0");
        bonusPeriod = newBonusPeriod;
        emit BonusPeriodUpdated(newBonusPeriod);
    }
}
