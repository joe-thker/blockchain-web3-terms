// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Minimal interface for an ERC20 token used for staking.
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/// @title DPoSec (Distributed Proof of Security)
/// @notice A dynamic and optimized contract where watchers stake tokens to provide security services.
/// The owner can register watchers, slash watchers if they fail security checks, and watchers can stake or unstake.
contract DPoSec is Ownable, ReentrancyGuard {
    /// @notice The ERC20 token used for staking (e.g. a stablecoin or governance token).
    IERC20 public stakingToken;

    /// @notice Represents a watcher with a staked balance.
    struct Watcher {
        address watcherAddress;
        uint256 stakedBalance;
        bool active;
    }

    // Mapping from watcher address => Watcher struct
    mapping(address => Watcher) public watchers;

    // The total stake from all watchers (for demonstration)
    uint256 public totalStaked;

    // --- Events ---
    event WatcherRegistered(address indexed watcher);
    event WatcherUnregistered(address indexed watcher);
    event Staked(address indexed watcher, uint256 amount);
    event Unstaked(address indexed watcher, uint256 amount);
    event Slashed(address indexed watcher, uint256 slashAmount);

    /// @notice Constructor sets the deployer as the contract owner and the ERC20 staking token.
    /// @param _stakingToken The ERC20 token contract address used for staking.
    constructor(address _stakingToken) Ownable(msg.sender) {
        require(_stakingToken != address(0), "Invalid token address");
        stakingToken = IERC20(_stakingToken);
    }

    // ------------------------------------------------------------------------
    // Watcher Management
    // ------------------------------------------------------------------------

    /// @notice The owner registers a new watcher, enabling them to stake tokens.
    /// @param watcher The address of the watcher to register.
    function registerWatcher(address watcher) external onlyOwner {
        require(watcher != address(0), "Invalid watcher address");
        Watcher storage w = watchers[watcher];
        require(!w.active, "Watcher already registered");

        w.watcherAddress = watcher;
        w.active = true;

        emit WatcherRegistered(watcher);
    }

    /// @notice The owner un-registers a watcher, preventing future stake changes. 
    /// The watcher must unstake before being fully removed, or the owner can slash if needed.
    /// @param watcher The address of the watcher to unregister.
    function unregisterWatcher(address watcher) external onlyOwner {
        Watcher storage w = watchers[watcher];
        require(w.active, "Watcher not registered");
        // Optionally: require w.stakedBalance == 0 or slash it. 
        // For demonstration, we allow watchers to remain with a stakedBalance. 
        // You can define your logic, e.g. slashing or forcing unstake.

        w.active = false;
        emit WatcherUnregistered(watcher);
    }

    // ------------------------------------------------------------------------
    // Staking
    // ------------------------------------------------------------------------

    /// @notice A registered watcher stakes an amount of tokens. Must have approved this contract for that amount.
    /// @param amount The number of tokens to stake.
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Stake amount must be > 0");
        Watcher storage w = watchers[msg.sender];
        require(w.active, "Not an active watcher");
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        
        w.stakedBalance += amount;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    /// @notice A watcher unstakes some of their tokens. 
    /// In a real system, you might have timelocks or partial restrictions.
    /// @param amount The number of tokens to unstake.
    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "Unstake amount must be > 0");
        Watcher storage w = watchers[msg.sender];
        require(w.active, "Not an active watcher");
        require(w.stakedBalance >= amount, "Insufficient staked balance");

        w.stakedBalance -= amount;
        totalStaked -= amount;

        bool success = stakingToken.transfer(msg.sender, amount);
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, amount);
    }

    // ------------------------------------------------------------------------
    // Slashing
    // ------------------------------------------------------------------------
    // If a watcher fails a security check, the owner can slash some or all of the watcher's stake.

    /// @notice The owner slashes a specified amount from a watcher's stake, sending it to the owner or a slash recipient.
    /// @param watcher The address of the watcher to slash.
    /// @param slashAmount The amount to slash from the watcher's stake.
    /// @param recipient The address that receives the slashed stake. Typically the protocol treasury or the contract's address.
    function slash(address watcher, uint256 slashAmount, address recipient) external onlyOwner nonReentrant {
        Watcher storage w = watchers[watcher];
        require(w.active, "Not an active watcher");
        require(w.stakedBalance >= slashAmount, "Slash exceeds staked balance");
        require(recipient != address(0), "Invalid slash recipient");

        w.stakedBalance -= slashAmount;
        totalStaked -= slashAmount;

        bool success = stakingToken.transfer(recipient, slashAmount);
        require(success, "Slash transfer failed");

        emit Slashed(watcher, slashAmount);
    }

    // ------------------------------------------------------------------------
    // View Functions
    // ------------------------------------------------------------------------

    /// @notice Returns the staked balance of a watcher.
    /// @param watcher The address of the watcher.
    /// @return The amount of staked tokens.
    function getStakedBalance(address watcher) external view returns (uint256) {
        return watchers[watcher].stakedBalance;
    }

    /// @notice Checks if an address is currently an active watcher.
    /// @param watcher The address to check.
    /// @return True if watcher is active, false otherwise.
    function isActiveWatcher(address watcher) external view returns (bool) {
        return watchers[watcher].active;
    }
}
