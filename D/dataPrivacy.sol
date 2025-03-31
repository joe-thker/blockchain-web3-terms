// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DataPrivacy
/// @notice This contract allows users to store their encrypted data on-chain.
/// Only the owner or addresses authorized by the owner can retrieve the encrypted data.
/// While all on-chain data is publicly accessible, this contract enforces access control to simulate privacy.
contract DataPrivacy is Ownable, ReentrancyGuard {
    // Mapping from user address to their encrypted data.
    mapping(address => string) private encryptedData;
    
    // Mapping for addresses authorized to view stored data.
    mapping(address => bool) public authorizedViewers;
    
    // --- Events ---
    event DataStored(address indexed user, bytes32 dataHash);
    event ViewerAuthorized(address indexed viewer);
    event ViewerRevoked(address indexed viewer);

    /// @notice Modifier to restrict access to only authorized viewers or the owner.
    modifier onlyAuthorizedViewer() {
        require(authorizedViewers[msg.sender] || msg.sender == owner(), "Not an authorized viewer");
        _;
    }

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // No additional initialization required.
    }

    /// @notice Authorizes an address to view stored encrypted data.
    /// @param viewer The address to authorize.
    function authorizeViewer(address viewer) external onlyOwner {
        require(viewer != address(0), "Invalid address");
        authorizedViewers[viewer] = true;
        emit ViewerAuthorized(viewer);
    }

    /// @notice Revokes an address's permission to view stored encrypted data.
    /// @param viewer The address to revoke.
    function revokeViewer(address viewer) external onlyOwner {
        require(authorizedViewers[viewer], "Viewer not authorized");
        authorizedViewers[viewer] = false;
        emit ViewerRevoked(viewer);
    }

    /// @notice Allows a user to store their encrypted data.
    /// @param data The encrypted data (produced off-chain) as a string.
    function storeEncryptedData(string calldata data) external nonReentrant {
        encryptedData[msg.sender] = data;
        // Emit the hash of the data for commitment purposes.
        emit DataStored(msg.sender, keccak256(abi.encodePacked(data)));
    }

    /// @notice Allows an authorized viewer (or the owner) to retrieve the encrypted data for a given user.
    /// @param user The address of the user whose data is requested.
    /// @return The encrypted data as a string.
    function getEncryptedData(address user) external view onlyAuthorizedViewer returns (string memory) {
        return encryptedData[user];
    }
}
