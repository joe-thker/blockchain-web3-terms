// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Minimal ERC20 interface for bridging (lock/unlock).
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/// @title DriveChain
/// @notice A dynamic, optimized contract illustrating a simplified "drive chain" bridging approach.
/// Users deposit (lock) ERC20 tokens in this contract to have them minted on the side chain. 
/// Later, the contract owner (or a trusted relayer) can unlock tokens on the main chain if they're burned on the side chain.
contract DriveChain is Ownable, ReentrancyGuard {
    /// @notice The ERC20 token used for bridging.
    IERC20 public bridgingToken;

    /// @notice Mapping from user address => the amount of tokens locked for bridging on main chain.
    mapping(address => uint256) public lockedBalance;

    // --- Events ---
    event DepositForBridge(address indexed user, uint256 amount);
    event UnlockAfterSidechainBurn(address indexed user, uint256 amount);

    /// @notice Constructor sets the bridging token address and the owner. 
    /// @param _token The ERC20 token contract to be locked/unlocked for bridging.
    constructor(address _token) Ownable(msg.sender) {
        require(_token != address(0), "Invalid token address");
        bridgingToken = IERC20(_token);
    }

    /// @notice Users lock tokens in this contract, removing them from circulation on the main chain 
    /// so they can be minted or represented on the side chain. The user must have approved this contract first.
    /// @param amount The number of tokens to deposit for bridging.
    function depositForBridge(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be > 0");
        bool success = bridgingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
        lockedBalance[msg.sender] += amount;

        emit DepositForBridge(msg.sender, amount);
    }

    /// @notice The owner (or a trusted relayer) can unlock tokens on the main chain if they've been burned 
    /// on the side chain. The user receives tokens back here. This effectively "redeems" the side chain tokens 
    /// for main chain tokens.
    /// @param user The address that had previously locked tokens and burned them on side chain.
    /// @param amount The number of tokens to unlock for this user.
    function unlockAfterSidechainBurn(address user, uint256 amount) external onlyOwner nonReentrant {
        require(user != address(0), "Invalid user address");
        require(lockedBalance[user] >= amount, "Insufficient locked balance");
        // Decrease the locked balance
        lockedBalance[user] -= amount;
        // Transfer tokens out to the user
        bool success = bridgingToken.transfer(user, amount);
        require(success, "Token transfer failed");

        emit UnlockAfterSidechainBurn(user, amount);
    }

    /// @notice Returns how many tokens a user has locked for bridging.
    /// @param user The address of the user.
    /// @return The locked token amount for bridging on main chain.
    function getLockedBalance(address user) external view returns (uint256) {
        return lockedBalance[user];
    }
}
