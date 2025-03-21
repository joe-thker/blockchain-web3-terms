// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockchainEnabledSmartLock
/// @notice A simple smart contract that simulates a blockchain-enabled smart lock.
contract BlockchainEnabledSmartLock {
    address public owner;
    bool public locked; // true if locked, false if unlocked

    // Mapping of authorized addresses
    mapping(address => bool) public authorizedUsers;

    // Events for logging actions.
    event LockStatusChanged(bool locked);
    event AccessGranted(address indexed user);
    event AccessRevoked(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorizedUsers[msg.sender] || msg.sender == owner, "Not authorized");
        _;
    }

    /// @notice Constructor sets the deployer as the owner and initializes the lock as locked.
    constructor() {
        owner = msg.sender;
        locked = true; // Initially locked.
    }

    /// @notice Allows the owner to grant access to an address.
    /// @param user The address to grant access.
    function grantAccess(address user) external onlyOwner {
        authorizedUsers[user] = true;
        emit AccessGranted(user);
    }

    /// @notice Allows the owner to revoke access from an address.
    /// @param user The address to revoke access.
    function revokeAccess(address user) external onlyOwner {
        authorizedUsers[user] = false;
        emit AccessRevoked(user);
    }

    /// @notice Allows an authorized user to lock the smart lock.
    function lock() external onlyAuthorized {
        locked = true;
        emit LockStatusChanged(true);
    }

    /// @notice Allows an authorized user to unlock the smart lock.
    function unlock() external onlyAuthorized {
        locked = false;
        emit LockStatusChanged(false);
    }

    /// @notice Retrieves the current status of the lock.
    /// @return True if the lock is locked, false if unlocked.
    function getLockStatus() external view returns (bool) {
        return locked;
    }
}
