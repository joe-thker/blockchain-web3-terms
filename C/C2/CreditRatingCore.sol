// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title CreditRatingCore
/// @notice This contract stores and manages credit ratings for addresses.
/// Authorized updaters (in addition to the owner) can assign, update, or remove ratings.
/// The contract is dynamic, optimized for storage, and secure.
contract CreditRatingCore is Ownable, ReentrancyGuard {
    // Structure for storing a credit rating.
    struct RatingInfo {
        uint256 ratingScore; // The credit score.
        uint256 updatedAt;   // Timestamp of the last update.
        bool exists;         // Flag to indicate if a rating exists.
    }
    
    // Mapping of addresses to their rating information.
    mapping(address => RatingInfo) public ratings;
    
    // Mapping to track additional authorized rating updaters.
    mapping(address => bool) public isAuthorizedUpdater;
    
    // --- Events ---
    event UpdaterAdded(address indexed updater);
    event UpdaterRemoved(address indexed updater);
    event RatingAssigned(address indexed account, uint256 ratingScore, uint256 timestamp);
    event RatingRemoved(address indexed account);
    
    /// @notice Modifier that allows only the owner or an authorized updater.
    modifier onlyUpdater() {
        require(msg.sender == owner() || isAuthorizedUpdater[msg.sender], "Not an authorized updater");
        _;
    }
    
    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // No additional initialization required.
    }
    
    // --- Authorization Management ---
    
    /// @notice Adds an authorized updater. Only the owner can call this.
    /// @param updater The address to add as an authorized updater.
    function addUpdater(address updater) external onlyOwner {
        require(updater != address(0), "Invalid updater address");
        require(!isAuthorizedUpdater[updater], "Updater already authorized");
        isAuthorizedUpdater[updater] = true;
        emit UpdaterAdded(updater);
    }
    
    /// @notice Removes an authorized updater. Only the owner can call this.
    /// @param updater The address to remove.
    function removeUpdater(address updater) external onlyOwner {
        require(isAuthorizedUpdater[updater], "Updater not authorized");
        isAuthorizedUpdater[updater] = false;
        emit UpdaterRemoved(updater);
    }
    
    // --- Credit Rating Management ---
    
    /// @notice Assigns or updates a credit rating for a specific address.
    /// @param account The address whose rating is being updated.
    /// @param score The new rating score (must be > 0).
    function setRating(address account, uint256 score) external onlyUpdater nonReentrant {
        require(account != address(0), "Invalid address");
        require(score > 0, "Rating score must be > 0");
        
        ratings[account] = RatingInfo({
            ratingScore: score,
            updatedAt: block.timestamp,
            exists: true
        });
        
        emit RatingAssigned(account, score, block.timestamp);
    }
    
    /// @notice Removes the credit rating for a specific address.
    /// @param account The address whose rating should be removed.
    function removeRating(address account) external onlyUpdater nonReentrant {
        require(ratings[account].exists, "No rating to remove");
        delete ratings[account];
        emit RatingRemoved(account);
    }
    
    // --- Helper Functions ---
    
    /// @notice Retrieves the rating information for a given address.
    /// @param account The address to query.
    /// @return ratingScore The credit rating score.
    /// @return updatedAt The timestamp when the rating was last updated.
    /// @return exists Whether a rating exists for this address.
    function getRating(address account)
        external
        view
        returns (uint256 ratingScore, uint256 updatedAt, bool exists)
    {
        RatingInfo memory info = ratings[account];
        return (info.ratingScore, info.updatedAt, info.exists);
    }
}
