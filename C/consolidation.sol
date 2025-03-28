// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Consolidation
/// @notice This contract allows users to deposit tokens in fragmented amounts and later consolidate
/// those deposits into a single balance. This process minimizes storage overhead and gas costs for future operations.
/// The contract is dynamic (with an adjustable consolidation threshold), optimized, and secure.
contract Consolidation is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // The ERC20 token that will be consolidated.
    IERC20 public immutable token;

    // Mapping to store each user's fragmented deposit amounts.
    mapping(address => uint256[]) private deposits;

    // Consolidated balance for each user.
    mapping(address => uint256) public consolidatedBalance;

    // Threshold at which deposits are automatically consolidated.
    uint256 public consolidationThreshold;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount);
    event Consolidated(address indexed user, uint256 consolidatedAmount, uint256 fragmentsConsolidated);
    event Withdrawn(address indexed user, uint256 amount);
    event ConsolidationThresholdUpdated(uint256 newThreshold);

    /// @notice Constructor sets the token to consolidate and the initial consolidation threshold.
    /// @param _token The address of the ERC20 token.
    /// @param _consolidationThreshold The number of deposit fragments triggering auto-consolidation.
    constructor(address _token, uint256 _consolidationThreshold) Ownable(msg.sender) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
        consolidationThreshold = _consolidationThreshold;
    }

    /// @notice Allows the owner to update the consolidation threshold.
    /// @param newThreshold The new consolidation threshold.
    function updateConsolidationThreshold(uint256 newThreshold) external onlyOwner {
        consolidationThreshold = newThreshold;
        emit ConsolidationThresholdUpdated(newThreshold);
    }

    /// @notice Deposit tokens into the contract as fragmented deposits.
    /// @param amount The amount of tokens to deposit.
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        token.safeTransferFrom(msg.sender, address(this), amount);
        deposits[msg.sender].push(amount);
        emit Deposited(msg.sender, amount);
        
        // Auto-consolidate if the number of fragments meets or exceeds the threshold.
        if (deposits[msg.sender].length >= consolidationThreshold) {
            _consolidate(msg.sender);
        }
    }

    /// @notice Manually consolidate your fragmented deposits into your consolidated balance.
    function consolidate() external nonReentrant {
        _consolidate(msg.sender);
    }

    /// @notice Internal function that sums all deposit fragments for a user, adds them to the consolidated balance,
    /// and clears the fragmented deposits.
    /// @param user The address of the user.
    function _consolidate(address user) internal {
        uint256[] storage userDeposits = deposits[user];
        require(userDeposits.length > 0, "No deposits to consolidate");

        uint256 sum = 0;
        uint256 count = userDeposits.length;
        for (uint256 i = 0; i < count; i++) {
            sum += userDeposits[i];
        }
        consolidatedBalance[user] += sum;
        delete deposits[user];
        emit Consolidated(user, consolidatedBalance[user], count);
    }

    /// @notice Withdraw tokens from your consolidated balance.
    /// @param amount The amount of tokens to withdraw.
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(consolidatedBalance[msg.sender] >= amount, "Insufficient consolidated balance");
        consolidatedBalance[msg.sender] -= amount;
        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Returns the number of fragmented deposit records for a user.
    /// @param user The address of the user.
    /// @return The count of deposit fragments.
    function getDepositFragmentCount(address user) external view returns (uint256) {
        return deposits[user].length;
    }

    /// @notice Returns the fragmented deposit amounts for a user.
    /// @param user The address of the user.
    /// @return An array containing the individual deposit fragment amounts.
    function getDepositFragments(address user) external view returns (uint256[] memory) {
        return deposits[user];
    }
}
